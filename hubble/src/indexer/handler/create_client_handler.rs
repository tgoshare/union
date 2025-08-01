use tracing::trace;

use crate::indexer::{
    api::IndexerError,
    event::create_client_event::CreateClientEvent,
    handler::EventContext,
    record::{change_counter::Changes, create_client_record::CreateClientRecord, ChainContext},
};
impl<'a> EventContext<'a, ChainContext, CreateClientEvent> {
    pub async fn handle(
        &self,
        tx: &mut sqlx::Transaction<'_, sqlx::Postgres>,
    ) -> Result<Changes, IndexerError> {
        trace!("handle({self:?})");

        CreateClientRecord::try_from(self)?.insert(tx).await
    }
}
