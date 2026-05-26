"""Unit tests for handover log."""

from __future__ import annotations

import pytest

from rogue_gateway.handover.log import HandoverEntry, HandoverLog


@pytest.mark.asyncio
async def test_handover_log_append() -> None:
    log = HandoverLog(":memory:")
    entry = HandoverEntry(
        gateway_id="test-gateway",
        session_id="sess-1",
        cli_type="opencode",
        event_type="message_sent",
        payload={"prompt": "hello"},
        sequence_number=1,
    )
    await log.append(entry)
    await log.close()


@pytest.mark.asyncio
async def test_handover_log_multiple_entries() -> None:
    log = HandoverLog(":memory:")
    for i in range(5):
        await log.append(
            HandoverEntry(
                gateway_id="test",
                session_id=f"sess-{i}",
                cli_type="opencode",
                event_type="message_sent",
                payload={},
                sequence_number=i,
            )
        )
    await log.close()
