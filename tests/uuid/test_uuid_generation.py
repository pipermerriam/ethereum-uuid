import uuid

deploy_contracts = [
    "UUIDProvider",
]


def test_uuid_provider(deploy_client, deployed_contracts, get_log_data):
    uuid_provider = deployed_contracts.UUIDProvider

    def get_uuid():
        txn_h = uuid_provider.UUID4()
        txn_r = deploy_client.wait_for_transaction(txn_h)

        print "gas:", int(txn_r['gasUsed'], 16)

        event_data = get_log_data(uuid_provider.UUID, txn_h)
        return event_data['uuid']

    seen = set()

    for i in range(10):
        u = uuid.UUID(bytes=get_uuid())
        assert str(u)[24] in {'8', '9', 'a', 'b'}
        assert str(u)[19] == '4'
        assert str(u) not in seen
        seen.add(str(u))
