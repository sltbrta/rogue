"""Handover sync — S3 bucket read/write for Mac ↔ cloud failover.

Snapshots full session state to Railway S3 bucket on session close or
periodic heartbeat. Cloud gateway polls for new snapshots on failover.
"""

from __future__ import annotations

import json
import logging
import os
from dataclasses import dataclass
from datetime import UTC, datetime
from typing import Any

import boto3
from botocore.config import Config as BotoConfig

logger = logging.getLogger(__name__)


@dataclass(slots=True)
class HandoverSnapshot:
    snapshot_id: str
    timestamp: str
    gateway_id: str
    active_sessions: list[dict[str, Any]]
    last_sequence_number: int


class HandoverSync:
    """Syncs handover log snapshots to/from S3-compatible storage."""

    def __init__(
        self,
        gateway_id: str = "",
        bucket: str = "",
        endpoint: str = "",
        access_key: str = "",
        secret_key: str = "",
    ) -> None:
        self._gateway_id = gateway_id or os.environ.get("GATEWAY_ID", "macbook-pro")
        self._bucket = bucket or os.environ.get("ROGUE_S3_BUCKET", "rogue-handover")
        self._endpoint = endpoint or os.environ.get("S3_ENDPOINT", "")
        self._access_key = access_key or os.environ.get("S3_ACCESS_KEY", "")
        self._secret_key = secret_key or os.environ.get("S3_SECRET_KEY", "")

        self._client = boto3.client(
            "s3",
            endpoint_url=self._endpoint if self._endpoint else None,
            aws_access_key_id=self._access_key,
            aws_secret_access_key=self._secret_key,
            config=BotoConfig(region_name="auto"),
        )

    def snapshot_key(self, snapshot_id: str) -> str:
        return f"{self._gateway_id}/snapshots/{snapshot_id}.json"

    def active_sessions_key(self) -> str:
        return f"{self._gateway_id}/active.json"

    async def upload_snapshot(self, snapshot: HandoverSnapshot) -> None:
        data = json.dumps(
            {
                "snapshot_id": snapshot.snapshot_id,
                "timestamp": snapshot.timestamp,
                "gateway_id": snapshot.gateway_id,
                "active_sessions": snapshot.active_sessions,
                "last_sequence_number": snapshot.last_sequence_number,
            }
        ).encode("utf-8")

        self._client.put_object(
            Bucket=self._bucket,
            Key=self.snapshot_key(snapshot.snapshot_id),
            Body=data,
            ContentType="application/json",
        )
        self._client.put_object(
            Bucket=self._bucket,
            Key=self.active_sessions_key(),
            Body=data,
            ContentType="application/json",
        )
        logger.info(
            "handover_sync.uploaded snapshot_id=%s gateway=%s",
            snapshot.snapshot_id,
            self._gateway_id,
        )

    async def download_latest(self, gateway_id: str) -> HandoverSnapshot | None:
        try:
            key = f"{gateway_id}/active.json"
            response = self._client.get_object(Bucket=self._bucket, Key=key)
            data = json.loads(response["Body"].read().decode("utf-8"))
            return HandoverSnapshot(
                snapshot_id=data["snapshot_id"],
                timestamp=data["timestamp"],
                gateway_id=data["gateway_id"],
                active_sessions=data["active_sessions"],
                last_sequence_number=data["last_sequence_number"],
            )
        except self._client.exceptions.NoSuchKey:
            logger.debug("handover_sync.no_snapshot gateway=%s", gateway_id)
            return None
        except Exception:
            logger.exception("handover_sync.download_failed gateway=%s", gateway_id)
            return None

    async def cleanup_old_snapshots(self, max_age_hours: int = 24) -> int:
        try:
            prefix = f"{self._gateway_id}/snapshots/"
            response = self._client.list_objects_v2(Bucket=self._bucket, Prefix=prefix)
            now = datetime.now(UTC)
            deleted = 0
            for obj in response.get("Contents", []):
                last_modified = obj["LastModified"]
                age = now - last_modified
                if age.total_seconds() > max_age_hours * 3600:
                    self._client.delete_object(Bucket=self._bucket, Key=obj["Key"])
                    deleted += 1
            return deleted
        except Exception:
            logger.exception("handover_sync.cleanup_failed")
            return 0
