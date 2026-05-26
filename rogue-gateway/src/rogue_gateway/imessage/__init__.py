"""iMessage bridge — Mac daemon bridging Messages.app to the Rogue gateway.

Runs only on macOS. Uses AppleScript (osascript) to read/send iMessages.
Maps conversations to CLI sessions: one iMessage chat = one ACP session.
"""

from __future__ import annotations
