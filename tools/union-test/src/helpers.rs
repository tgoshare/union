use unionlabs::primitives::FixedBytes;
#[derive(Debug, Clone, PartialEq)]
pub struct ConnectionConfirm {
    pub connection_id: u32,
    pub counterparty_connection_id: u32,
}

#[derive(Debug, Clone, PartialEq)]
pub struct ChannelOpenConfirm {
    pub channel_id: u32,
    pub counterparty_channel_id: u32,
}

#[derive(Debug, Clone, PartialEq)]
pub struct CreateClientConfirm {
    pub client_id: u32,
}

#[derive(Debug, Clone, PartialEq)]
pub struct PacketRecv {
    pub packet_hash: FixedBytes<32>,
}

#[derive(Debug, Clone, PartialEq)]
pub struct PacketAck {
    pub packet_hash: FixedBytes<32>,
}

#[derive(Debug, Clone, PartialEq)]
pub struct PacketSend {
    pub packet_hash: FixedBytes<32>,
}

#[derive(Debug, Clone, PartialEq)]
pub struct Delegate {
    pub validator: String,
}

#[derive(Debug, Clone, PartialEq)]
pub struct WithdrawRewards {
    pub validator: String,
    pub amount: String,
}
