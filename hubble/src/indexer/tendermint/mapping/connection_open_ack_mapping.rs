use tracing::trace;

use crate::indexer::{
    api::IndexerError,
    event::{connection_open_ack_event::ConnectionOpenAckEvent, supported::SupportedBlockEvent},
    tendermint::{fetcher_client::TmFetcherClient, mapping::decoder::Decoder},
};

impl TmFetcherClient {
    pub fn to_connection_open_ack(
        &self,
        log: &Decoder,
    ) -> Result<Vec<SupportedBlockEvent>, IndexerError> {
        trace!("to_connection_open_ack - {log}");

        Ok(vec![SupportedBlockEvent::ConnectionOpenAck {
            inner: ConnectionOpenAckEvent {
                header: log.header()?,
                connection_id: log.event.connection_id()?,
                client_id: log.event.client_id()?,
                counterparty_client_id: log.event.counterparty_client_id()?,
                counterparty_connection_id: log.event.counterparty_connection_id()?,
            },
        }])
    }
}
