use super::{Client, ClientStateBuilder, Invitation, RUNTIME};
use crate::platform;
use anyhow::{bail, Context, Result};
use assign::assign;
use effektio_core::ruma::api::client::{account::register, uiaa};
use effektio_core::RestoreToken;
use futures::{Stream, channel::mpsc::Receiver};
use lazy_static::lazy_static;
use matrix_sdk::Session;
use tokio::runtime;
use url::Url;

pub struct LoginResponse {
    client: Client,
    past_invitation_rx: Result<Receiver<Invitation>>,
}

impl LoginResponse {
    pub fn get_client(&self) -> &Client {
        &self.client
    }

    // mut is needed to wrap invitation with stream in api.rsh
    pub fn get_past_invitation_rx(&mut self) -> &mut Result<Receiver<Invitation>> {
        &mut self.past_invitation_rx
    }
}

pub async fn guest_client(base_path: String, homeurl: String) -> Result<LoginResponse> {
    let config = platform::new_client_config(base_path, homeurl.clone())?.homeserver_url(homeurl);
    let mut guest_registration = register::v3::Request::new();
    guest_registration.kind = register::RegistrationKind::Guest;
    RUNTIME
        .spawn(async move {
            let client = config.build().await?;
            let register = client.register(guest_registration).await?;
            let session = Session {
                access_token: register.access_token.context("no access token given")?,
                user_id: register.user_id,
                device_id: register
                    .device_id
                    .clone()
                    .context("device id is given by server")?,
            };
            client.restore_login(session).await?;
            let c = Client::new(
                client,
                ClientStateBuilder::default().is_guest(true).build()?,
            );
            let mut past_invitation_rx = c.start_sync();
            Ok(LoginResponse {
                client: c,
                past_invitation_rx,
            })
        })
        .await?
}

pub async fn login_with_token(base_path: String, restore_token: String) -> Result<LoginResponse> {
    let RestoreToken {
        session,
        homeurl,
        is_guest,
    } = serde_json::from_str(&restore_token)?;
    let config = platform::new_client_config(base_path, session.user_id.to_string())?
        .homeserver_url(homeurl);
    // First we need to log in.
    RUNTIME
        .spawn(async move {
            let client = config.build().await?;
            client.restore_login(session).await?;
            let c = Client::new(
                client,
                ClientStateBuilder::default().is_guest(is_guest).build()?,
            );
            let mut past_invitation_rx = c.start_sync();
            Ok(LoginResponse {
                client: c,
                past_invitation_rx,
            })
        })
        .await?
}

pub async fn login_new_client(
    base_path: String,
    username: String,
    password: String,
) -> Result<LoginResponse> {
    let user = ruma::OwnedUserId::try_from(username.clone())?;
    let mut config = platform::new_client_config(base_path, username)?.user_id(&user);
    if user.server_name().as_str() == "effektio.org" {
        // effektio.org has problems with the .well-known-setup at the moment
        config = config.homeserver_url("https://matrix.effektio.org");
    }

    // First we need to log in.
    RUNTIME
        .spawn(async move {
            let client = config.build().await?;
            client.login(user, &password, None, None).await?;
            let c = Client::new(
                client,
                ClientStateBuilder::default().is_guest(false).build()?,
            );
            let mut past_invitation_rx = c.start_sync();
            Ok(LoginResponse {
                client: c,
                past_invitation_rx,
            })
        })
        .await?
}

pub async fn register_with_registration_token(
    base_path: String,
    username: String,
    password: String,
    registration_token: String,
) -> Result<LoginResponse> {
    let user = ruma::OwnedUserId::try_from(username.clone())?;
    let config = platform::new_client_config(base_path, username.clone())?.user_id(&user);
    // First we need to log in.
    RUNTIME
        .spawn(async move {
            let client = config.build().await?;
            if let Err(resp) = client.register(register::v3::Request::new()).await {
                if let Some(_response) = resp.uiaa_response() {
                    // FIXME: do actually check the registration types...
                    let request = assign!(register::v3::Request::new(), {
                        username: Some(&username),
                        password: Some(&password),

                        auth: Some(uiaa::AuthData::RegistrationToken(
                            uiaa::RegistrationToken::new(&registration_token),
                        )),
                    });
                    client.register(request).await?;
                } else {
                    anyhow::bail!("Server did not indicate how to  allow registration.");
                }
            } else {
                anyhow::bail!("Server is not set up to allow registration.");
            }

            let c = Client::new(
                client,
                ClientStateBuilder::default().is_guest(false).build()?,
            );
            let mut past_invitation_rx = c.start_sync();
            Ok(LoginResponse {
                client: c,
                past_invitation_rx,
            })
        })
        .await?
}
