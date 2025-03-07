use derive_builder::Builder;

pub static APP_SETTINGS_FIELD: &str = "global.acter.app_settings";

use matrix_sdk::ruma::events::{macros::EventContent, EmptyStateKey};
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, Deserialize, Serialize, Builder)]
pub struct SimpleSettingWithTurnOff {
    active: bool,
}

impl Default for SimpleSettingWithTurnOff {
    fn default() -> Self {
        SimpleSettingWithTurnOff { active: true }
    }
}

impl SimpleSettingWithTurnOff {
    pub fn active(&self) -> bool {
        self.active
    }
    pub fn updater(&self) -> SimpleSettingWithTurnOffBuilder {
        SimpleSettingWithTurnOffBuilder::default()
            .active(self.active)
            .to_owned()
    }
}

pub type NewsSettings = SimpleSettingWithTurnOff;
pub type PinsSettings = SimpleSettingWithTurnOff;
pub type EventsSettings = SimpleSettingWithTurnOff;

#[derive(Clone, Debug, Deserialize, Serialize, EventContent, Builder, Default)]
#[ruma_event(type = "global.acter.app_settings", kind = State, state_key_type = EmptyStateKey)]
pub struct ActerAppSettingsContent {
    news: Option<NewsSettings>,
    pins: Option<NewsSettings>,
    events: Option<EventsSettings>,
}

impl ActerAppSettingsContent {
    pub fn news(&self) -> NewsSettings {
        self.news.clone().unwrap_or_default()
    }
    pub fn pins(&self) -> PinsSettings {
        self.pins.clone().unwrap_or_default()
    }
    pub fn events(&self) -> EventsSettings {
        self.events.clone().unwrap_or_default()
    }

    pub fn updater(&self) -> ActerAppSettingsContentBuilder {
        ActerAppSettingsContentBuilder::default()
            .news(self.news.clone())
            .pins(self.pins.clone())
            .events(self.events.clone())
            .to_owned()
    }
}
