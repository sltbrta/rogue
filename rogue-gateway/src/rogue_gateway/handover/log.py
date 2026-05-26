"""Handover log — structured session activity recording."""

from __future__ import annotations

import json
from dataclasses import dataclass, field
from datetime import UTC, datetime
from pathlib import Path
from typing import Any

import aiosqlite


@dataclass(slots=True)
class HandoverEntry:
    timestamp: str = field(default_factory=lambda: datetime.now(UTC).isoformat())
    gateway_id: str = ""
    session_id: str = ""
    cli_type: str = ""
    event_type: str = ""
    payload: dict[str, Any] = field(default_factory=dict)
    sequence_number: int = 0


class HandoverLog:
    """SQLite-backed structured handover log."""

    def __init__(self, db_path: str | Path = ":memory:") -> None:
        self._db_path = Path(db_path)
        self._db: aiosqlite.Connection | None = None

    async def _ensure_db(self) -> aiosqlite.Connection:
        if self._db is None:
            self._db = await aiosqlite.connect(str(self._db_path))
            await self._db.execute("""
                CREATE TABLE IF NOT EXISTS handover_log (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    timestamp TEXT NOT NULL,
                    gateway_id TEXT NOT NULL,
                    session_id TEXT NOT NULL,
                    cli_type TEXT NOT NULL,
                    event_type TEXT NOT NULL,
                    payload TEXT NOT NULL DEFAULT '{}',
                    sequence_number INTEGER NOT NULL
                )
            """)
            await self._db.execute(
                "CREATE INDEX IF NOT EXISTS idx_session ON handover_log(session_id)"
            )
            await self._db.commit()
        return self._db

    async def append(self, entry: HandoverEntry) -> None:
        db = await self._ensure_db()
        await db.execute(
            "INSERT INTO handover_log "
            "(timestamp, gateway_id, session_id, cli_type, event_type, payload, sequence_number) "
            "VALUES (?, ?, ?, ?, ?, ?, ?)",
            (
                entry.timestamp,
                entry.gateway_id,
                entry.session_id,
                entry.cli_type,
                entry.event_type,
                json.dumps(entry.payload),
                entry.sequence_number,
            ),
        )
        await db.commit()

    async def close(self) -> None:
        if self._db:
            await self._db.close()
            self._db = None
