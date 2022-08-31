use anyhow::Result;
use futures::{
    channel::mpsc::{channel, Receiver, Sender},
    StreamExt,
};
use log::{info, warn};
use matrix_sdk::{
    config::SyncSettings,
    deserialized_responses::Rooms,
    encryption::{
        identities::UserIdentity,
        verification::{SasVerification, Verification, VerificationRequest},
    },
    ruma::{
        api::client::sync::sync_events::v3::ToDevice,
        events::{
            key::verification::{cancel::CancelCode, VerificationMethod},
            room::message::MessageType,
            AnySyncMessageLikeEvent, AnySyncRoomEvent, AnyToDeviceEvent, SyncMessageLikeEvent,
        },
        UserId,
    },
    Client,
};
use parking_lot::Mutex;
use std::sync::Arc;

use super::RUNTIME;

#[derive(Clone, Debug)]
pub struct SessionVerificationEvent {
    client: Client,
    event_name: String,
    txn_id: String,
    sender: String,
    /// for request/ready/start events
    launcher: Option<String>,
    /// for cancel event
    cancel_code: Option<CancelCode>,
    /// for cancel event
    reason: Option<String>,
}

impl SessionVerificationEvent {
    pub(crate) fn new(
        client: &Client,
        event_name: String,
        txn_id: String,
        sender: String,
        launcher: Option<String>,
        cancel_code: Option<CancelCode>,
        reason: Option<String>,
    ) -> Self {
        SessionVerificationEvent {
            client: client.clone(),
            event_name,
            txn_id,
            sender,
            launcher,
            cancel_code,
            reason,
        }
    }

    pub fn get_event_name(&self) -> String {
        self.event_name.clone()
    }

    pub fn get_txn_id(&self) -> String {
        self.txn_id.clone()
    }

    pub fn get_sender(&self) -> String {
        self.sender.clone()
    }

    pub fn get_cancel_code(&self) -> Option<String> {
        self.cancel_code.clone().map(|e| e.as_str().to_owned())
    }

    pub fn get_reason(&self) -> Option<String> {
        self.reason.clone()
    }

    pub async fn accept_verification_request(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = UserId::parse(self.sender.clone()).expect("Couldn't parse the user id");
        let txn_id = self.txn_id.clone();
        RUNTIME
            .spawn(async move {
                let request = client
                    .encryption()
                    .get_verification_request(&sender, txn_id.as_str())
                    .await
                    .expect("Could not get request object");
                request
                    .accept()
                    .await
                    .expect("Can't accept verification request");
                Ok(true)
            })
            .await?
    }

    pub async fn cancel_verification_request(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = UserId::parse(self.sender.clone()).expect("Couldn't parse the user id");
        let txn_id = self.txn_id.clone();
        RUNTIME
            .spawn(async move {
                let request = client
                    .encryption()
                    .get_verification_request(&sender, txn_id.as_str())
                    .await
                    .expect("Could not get request object");
                request
                    .cancel()
                    .await
                    .expect("Can't cancel verification request");
                Ok(true)
            })
            .await?
    }

    pub async fn accept_verification_request_with_methods(
        &self,
        methods: &mut Vec<String>,
    ) -> Result<bool> {
        let client = self.client.clone();
        let sender = UserId::parse(self.sender.clone()).expect("Couldn't parse the user id");
        let txn_id = self.txn_id.clone();
        let _methods: Vec<VerificationMethod> =
            (*methods).iter().map(|e| e.as_str().into()).collect();
        RUNTIME
            .spawn(async move {
                let request = client
                    .encryption()
                    .get_verification_request(&sender, txn_id.as_str())
                    .await
                    .expect("Could not get request object");
                request
                    .accept_with_methods(_methods)
                    .await
                    .expect("Can't accept verification request");
                Ok(true)
            })
            .await?
    }

    pub async fn start_sas_verification(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = UserId::parse(self.sender.clone()).expect("Couldn't parse the user id");
        let txn_id = self.txn_id.clone();
        RUNTIME
            .spawn(async move {
                let request = client
                    .encryption()
                    .get_verification_request(&sender, txn_id.as_str())
                    .await
                    .expect("Could not get request object");
                let sas_verification = request
                    .start_sas()
                    .await
                    .expect("Can't accept verification request");
                Ok(sas_verification.is_some())
            })
            .await?
    }

    pub fn was_triggered_from_this_device(&self) -> Option<bool> {
        let device_id = self
            .client
            .device_id()
            .expect("guest user cannot get device id");
        self.launcher.clone().map(|dev_id| dev_id == *device_id)
    }

    pub async fn accept_sas_verification(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = UserId::parse(self.sender.clone()).expect("Couldn't parse the user id");
        let txn_id = self.txn_id.clone();
        RUNTIME
            .spawn(async move {
                if let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&sender, txn_id.as_str())
                    .await
                {
                    sas.accept().await.unwrap();
                    Ok(true)
                } else {
                    Ok(false)
                }
            })
            .await?
    }

    pub async fn cancel_sas_verification(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = UserId::parse(self.sender.clone()).expect("Couldn't parse the user id");
        let txn_id = self.txn_id.clone();
        RUNTIME
            .spawn(async move {
                if let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&sender, txn_id.as_str())
                    .await
                {
                    sas.cancel().await.unwrap();
                    Ok(true)
                } else {
                    Ok(false)
                }
            })
            .await?
    }

    pub async fn send_verification_key(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = UserId::parse(self.sender.clone()).expect("Couldn't parse the user id");
        let txn_id = self.txn_id.clone();
        RUNTIME
            .spawn(async move {
                client.sync_once(SyncSettings::default()).await?; // send_outgoing_requests is called there
                Ok(true)
            })
            .await?
    }

    pub async fn cancel_verification_key(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = UserId::parse(self.sender.clone()).expect("Couldn't parse the user id");
        let txn_id = self.txn_id.clone();
        RUNTIME
            .spawn(async move {
                if let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&sender, txn_id.as_str())
                    .await
                {
                    sas.cancel().await.unwrap();
                    Ok(true)
                } else {
                    Ok(false)
                }
            })
            .await?
    }

    pub async fn get_verification_emoji(&self) -> Result<Vec<SessionVerificationEmoji>> {
        let client = self.client.clone();
        let sender = UserId::parse(self.sender.clone()).expect("Couldn't parse the user id");
        let txn_id = self.txn_id.clone();
        RUNTIME
            .spawn(async move {
                if let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&sender, txn_id.as_str())
                    .await
                {
                    if let Some(items) = sas.emoji() {
                        let sequence = items
                            .iter()
                            .map(|e| SessionVerificationEmoji {
                                symbol: e.symbol.chars().collect::<Vec<_>>()[0] as u32,
                                description: e.description.to_string(),
                            })
                            .collect::<Vec<_>>();
                        return Ok(sequence);
                    }
                }
                Ok(vec![])
            })
            .await?
    }

    pub async fn confirm_sas_verification(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = UserId::parse(self.sender.clone()).expect("Couldn't parse the user id");
        let txn_id = self.txn_id.clone();
        RUNTIME
            .spawn(async move {
                if let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&sender, txn_id.as_str())
                    .await
                {
                    sas.confirm().await.unwrap();
                    Ok(sas.is_done())
                } else {
                    Ok(false)
                }
            })
            .await?
    }

    pub async fn mismatch_sas_verification(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = UserId::parse(self.sender.clone()).expect("Couldn't parse the user id");
        let txn_id = self.txn_id.clone();
        RUNTIME
            .spawn(async move {
                if let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&sender, txn_id.as_str())
                    .await
                {
                    sas.mismatch().await.unwrap();
                    Ok(true)
                } else {
                    Ok(false)
                }
            })
            .await?
    }

    pub async fn review_verification_mac(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = UserId::parse(self.sender.clone()).expect("Couldn't parse the user id");
        let txn_id = self.txn_id.clone();
        RUNTIME
            .spawn(async move {
                if let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&sender, txn_id.as_str())
                    .await
                {
                    Ok(sas.is_done())
                } else {
                    Ok(false)
                }
            })
            .await?
    }
}

#[derive(Clone, Debug)]
pub struct SessionVerificationEmoji {
    symbol: u32,
    description: String,
}

impl SessionVerificationEmoji {
    pub fn symbol(&self) -> u32 {
        self.symbol
    }

    pub fn description(&self) -> String {
        self.description.clone()
    }
}

#[derive(Clone)]
pub struct SessionVerificationController {
    event_tx: Sender<SessionVerificationEvent>,
    event_rx: Arc<Mutex<Option<Receiver<SessionVerificationEvent>>>>,
}

impl SessionVerificationController {
    pub(crate) fn new() -> Self {
        let (tx, rx) = channel::<SessionVerificationEvent>(10); // dropping after more than 10 items queued
        SessionVerificationController {
            event_tx: tx,
            event_rx: Arc::new(Mutex::new(Some(rx))),
        }
    }

    pub fn get_event_rx(&self) -> Option<Receiver<SessionVerificationEvent>> {
        self.event_rx.lock().take()
    }

    fn handle_sync_messages(&self, client: &Client, evt: &AnySyncMessageLikeEvent) {
        let mut event_tx = self.event_tx.clone();
        match evt {
            AnySyncMessageLikeEvent::RoomMessage(SyncMessageLikeEvent::Original(ev)) => {
                if let MessageType::VerificationRequest(_) = &ev.content.msgtype {
                    let dev_id = client.device_id().expect("guest user cannot get device id");
                    info!("{} got {}", dev_id.to_string(), evt.event_type());
                    let sender = ev.sender.to_string();
                    let txn_id = ev.event_id.to_string();
                    let msg = SessionVerificationEvent::new(
                        client,
                        evt.event_type().to_string(),
                        txn_id.clone(),
                        sender,
                        None,
                        None,
                        None,
                    );
                    if let Err(e) = event_tx.try_send(msg) {
                        warn!("Dropping event for {}: {}", txn_id, e);
                    }
                }
            }
            AnySyncMessageLikeEvent::KeyVerificationReady(SyncMessageLikeEvent::Original(ev)) => {
                let dev_id = client.device_id().expect("guest user cannot get device id");
                info!("{} got {}", dev_id.to_string(), evt.event_type());
                let sender = ev.sender.to_string();
                let txn_id = ev.content.relates_to.event_id.as_str().to_owned();
                let from_device = ev.content.from_device.to_string();
                let msg = SessionVerificationEvent::new(
                    client,
                    evt.event_type().to_string(),
                    txn_id.clone(),
                    sender,
                    Some(from_device),
                    None,
                    None,
                );
                if let Err(e) = event_tx.try_send(msg) {
                    warn!("Dropping event for {}: {}", txn_id, e);
                }
            }
            AnySyncMessageLikeEvent::KeyVerificationStart(SyncMessageLikeEvent::Original(ev)) => {
                let dev_id = client.device_id().expect("guest user cannot get device id");
                info!("{} got {}", dev_id.to_string(), evt.event_type());
                let sender = ev.sender.to_string();
                let txn_id = ev.content.relates_to.event_id.as_str().to_owned();
                let from_device = ev.content.from_device.to_string();
                let msg = SessionVerificationEvent::new(
                    client,
                    evt.event_type().to_string(),
                    txn_id.clone(),
                    sender,
                    Some(from_device),
                    None,
                    None,
                );
                if let Err(e) = event_tx.try_send(msg) {
                    warn!("Dropping event for {}: {}", txn_id, e);
                }
            }
            AnySyncMessageLikeEvent::KeyVerificationAccept(SyncMessageLikeEvent::Original(ev)) => {
                let dev_id = client.device_id().expect("guest user cannot get device id");
                info!("{} got {}", dev_id.to_string(), evt.event_type());
                let sender = ev.sender.to_string();
                let txn_id = ev.content.relates_to.event_id.as_str().to_owned();
                let msg = SessionVerificationEvent::new(
                    client,
                    evt.event_type().to_string(),
                    txn_id.clone(),
                    sender,
                    None,
                    None,
                    None,
                );
                if let Err(e) = event_tx.try_send(msg) {
                    warn!("Dropping event for {}: {}", txn_id, e);
                }
            }
            AnySyncMessageLikeEvent::KeyVerificationCancel(SyncMessageLikeEvent::Original(ev)) => {
                let dev_id = client.device_id().expect("guest user cannot get device id");
                info!("{} got {}", dev_id.to_string(), evt.event_type());
                let sender = ev.sender.to_string();
                let txn_id = ev.content.relates_to.event_id.as_str().to_owned();
                let cancel_code = ev.content.code.clone();
                let reason = ev.content.reason.clone();
                let msg = SessionVerificationEvent::new(
                    client,
                    evt.event_type().to_string(),
                    txn_id.clone(),
                    sender,
                    None,
                    Some(cancel_code),
                    Some(reason),
                );
                if let Err(e) = event_tx.try_send(msg) {
                    warn!("Dropping event for {}: {}", txn_id, e);
                }
            }
            AnySyncMessageLikeEvent::KeyVerificationKey(SyncMessageLikeEvent::Original(ev)) => {
                let dev_id = client.device_id().expect("guest user cannot get device id");
                info!("{} got {}", dev_id.to_string(), evt.event_type());
                let sender = ev.sender.to_string();
                let txn_id = ev.content.relates_to.event_id.as_str().to_owned();
                let msg = SessionVerificationEvent::new(
                    client,
                    evt.event_type().to_string(),
                    txn_id.clone(),
                    sender,
                    None,
                    None,
                    None,
                );
                if let Err(e) = event_tx.try_send(msg) {
                    warn!("Dropping event for {}: {}", txn_id, e);
                }
            }
            AnySyncMessageLikeEvent::KeyVerificationMac(SyncMessageLikeEvent::Original(ev)) => {
                let dev_id = client.device_id().expect("guest user cannot get device id");
                info!("{} got {}", dev_id.to_string(), evt.event_type());
                let sender = ev.sender.to_string();
                let txn_id = ev.content.relates_to.event_id.as_str().to_owned();
                let msg = SessionVerificationEvent::new(
                    client,
                    evt.event_type().to_string(),
                    txn_id.clone(),
                    sender,
                    None,
                    None,
                    None,
                );
                if let Err(e) = event_tx.try_send(msg) {
                    warn!("Dropping event for {}: {}", txn_id, e);
                }
            }
            AnySyncMessageLikeEvent::KeyVerificationDone(SyncMessageLikeEvent::Original(ev)) => {
                let dev_id = client.device_id().expect("guest user cannot get device id");
                info!("{} got {}", dev_id.to_string(), evt.event_type());
                let sender = ev.sender.to_string();
                let txn_id = ev.content.relates_to.event_id.as_str().to_owned();
                let msg = SessionVerificationEvent::new(
                    client,
                    evt.event_type().to_string(),
                    txn_id.clone(),
                    sender,
                    None,
                    None,
                    None,
                );
                if let Err(e) = event_tx.try_send(msg) {
                    warn!("Dropping event for {}: {}", txn_id, e);
                }
            }
            _ => {}
        }
    }

    pub(crate) fn process_sync_messages(&self, client: &Client, rooms: &Rooms) {
        for (room_id, room_info) in rooms.join.iter() {
            for event in room_info
                .timeline
                .events
                .iter()
                .filter_map(|ev| ev.event.deserialize().ok())
            {
                if let AnySyncRoomEvent::MessageLike(ref evt) = event {
                    self.handle_sync_messages(client, evt);
                }
            }
        }
    }

    fn handle_to_device_messages(&self, client: &Client, evt: &AnyToDeviceEvent) {
        let mut event_tx = self.event_tx.clone();
        match evt {
            AnyToDeviceEvent::KeyVerificationRequest(ref ev) => {
                let dev_id = client
                    .device_id()
                    .expect("guest user cannot get device id")
                    .to_string();
                info!("{} got {}", dev_id, evt.event_type());
                let sender = ev.sender.to_string();
                let txn_id = ev.content.transaction_id.to_string();
                let from_device = ev.content.from_device.to_string();
                let msg = SessionVerificationEvent::new(
                    client,
                    evt.event_type().to_string(),
                    txn_id.clone(),
                    sender,
                    Some(from_device),
                    None,
                    None,
                );
                if let Err(e) = event_tx.try_send(msg) {
                    warn!("Dropping transaction for {}: {}", txn_id, e);
                }
            }
            AnyToDeviceEvent::KeyVerificationReady(ref ev) => {
                let dev_id = client.device_id().expect("guest user cannot get device id");
                info!("{} got {}", dev_id.to_string(), evt.event_type());
                let sender = ev.sender.to_string();
                let txn_id = ev.content.transaction_id.to_string();
                let from_device = ev.content.from_device.to_string();
                let msg = SessionVerificationEvent::new(
                    client,
                    evt.event_type().to_string(),
                    txn_id.clone(),
                    sender,
                    Some(from_device),
                    None,
                    None,
                );
                if let Err(e) = event_tx.try_send(msg) {
                    warn!("Dropping transaction for {}: {}", txn_id, e);
                }
            }
            AnyToDeviceEvent::KeyVerificationStart(ref ev) => {
                let dev_id = client.device_id().expect("guest user cannot get device id");
                info!("{} got {}", dev_id.to_string(), evt.event_type());
                let sender = ev.sender.to_string();
                let txn_id = ev.content.transaction_id.to_string();
                let from_device = ev.content.from_device.to_string();
                let msg = SessionVerificationEvent::new(
                    client,
                    evt.event_type().to_string(),
                    txn_id.clone(),
                    sender,
                    Some(from_device),
                    None,
                    None,
                );
                if let Err(e) = event_tx.try_send(msg) {
                    warn!("Dropping transaction for {}: {}", txn_id, e);
                }
            }
            AnyToDeviceEvent::KeyVerificationAccept(ref ev) => {
                let dev_id = client.device_id().expect("guest user cannot get device id");
                info!("{} got {}", dev_id.to_string(), evt.event_type());
                let sender = ev.sender.to_string();
                let txn_id = ev.content.transaction_id.to_string();
                let msg = SessionVerificationEvent::new(
                    client,
                    evt.event_type().to_string(),
                    txn_id.clone(),
                    sender,
                    None,
                    None,
                    None,
                );
                if let Err(e) = event_tx.try_send(msg) {
                    warn!("Dropping transaction for {}: {}", txn_id, e);
                }
            }
            AnyToDeviceEvent::KeyVerificationCancel(ref ev) => {
                let dev_id = client.device_id().expect("guest user cannot get device id");
                info!("{} got {}", dev_id.to_string(), evt.event_type());
                let sender = ev.sender.to_string();
                let txn_id = ev.content.transaction_id.to_string();
                let cancel_code = ev.content.code.clone();
                let reason = ev.content.reason.clone();
                let msg = SessionVerificationEvent::new(
                    client,
                    evt.event_type().to_string(),
                    txn_id.clone(),
                    sender,
                    None,
                    Some(cancel_code),
                    Some(reason),
                );
                if let Err(e) = event_tx.try_send(msg) {
                    warn!("Dropping transaction for {}: {}", txn_id, e);
                }
            }
            AnyToDeviceEvent::KeyVerificationKey(ref ev) => {
                let dev_id = client.device_id().expect("guest user cannot get device id");
                info!("{} got {}", dev_id.to_string(), evt.event_type());
                let sender = ev.sender.to_string();
                let txn_id = ev.content.transaction_id.to_string();
                let msg = SessionVerificationEvent::new(
                    client,
                    evt.event_type().to_string(),
                    txn_id.clone(),
                    sender,
                    None,
                    None,
                    None,
                );
                if let Err(e) = event_tx.try_send(msg) {
                    warn!("Dropping transaction for {}: {}", txn_id, e);
                }
            }
            AnyToDeviceEvent::KeyVerificationMac(ref ev) => {
                let dev_id = client.device_id().expect("guest user cannot get device id");
                info!("{} got {}", dev_id.to_string(), evt.event_type());
                let sender = ev.sender.to_string();
                let txn_id = ev.content.transaction_id.to_string();
                let msg = SessionVerificationEvent::new(
                    client,
                    evt.event_type().to_string(),
                    txn_id.clone(),
                    sender,
                    None,
                    None,
                    None,
                );
                if let Err(e) = event_tx.try_send(msg) {
                    warn!("Dropping transaction for {}: {}", txn_id, e);
                }
            }
            AnyToDeviceEvent::KeyVerificationDone(ref ev) => {
                let dev_id = client.device_id().expect("guest user cannot get device id");
                info!("{} got {}", dev_id.to_string(), evt.event_type());
                let sender = ev.sender.to_string();
                let txn_id = ev.content.transaction_id.to_string();
                let msg = SessionVerificationEvent::new(
                    client,
                    evt.event_type().to_string(),
                    txn_id.clone(),
                    sender,
                    None,
                    None,
                    None,
                );
                if let Err(e) = event_tx.try_send(msg) {
                    warn!("Dropping transaction for {}: {}", txn_id, e);
                }
            }
            _ => {}
        }
    }

    pub(crate) fn process_to_device_messages(&self, client: &Client, to_device: ToDevice) {
        for evt in to_device
            .events
            .into_iter()
            .filter_map(|e| e.deserialize().ok())
        {
            self.handle_to_device_messages(client, &evt);
        }
    }
}
