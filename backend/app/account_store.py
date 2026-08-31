import sqlite3
from datetime import UTC, datetime
from pathlib import Path

from .config import get_settings


def _db_path() -> Path:
    return Path(get_settings().data_dir) / "accounts.db"


def _connect(db_path: Path) -> sqlite3.Connection:
    db_path.parent.mkdir(parents=True, exist_ok=True)
    conn = sqlite3.connect(db_path)
    conn.row_factory = sqlite3.Row
    return conn


def _init(db_path: Path) -> None:
    with _connect(db_path) as conn:
        conn.execute(
            """
            CREATE TABLE IF NOT EXISTS accounts (
                email TEXT PRIMARY KEY,
                channel_id TEXT NOT NULL,
                channel_title TEXT NOT NULL,
                avatar_url TEXT NOT NULL DEFAULT '',
                refresh_token TEXT NOT NULL,
                created_at TEXT NOT NULL,
                updated_at TEXT NOT NULL
            )
            """
        )


def list_accounts(db_path: Path | None = None) -> list[dict]:
    path = db_path or _db_path()
    _init(path)
    with _connect(path) as conn:
        rows = conn.execute(
            "SELECT email, channel_id, channel_title, avatar_url "
            "FROM accounts ORDER BY updated_at DESC"
        ).fetchall()
    return [dict(r) for r in rows]


def get_account(email: str, db_path: Path | None = None) -> dict | None:
    path = db_path or _db_path()
    _init(path)
    with _connect(path) as conn:
        row = conn.execute(
            "SELECT email, channel_id, channel_title, avatar_url, refresh_token "
            "FROM accounts WHERE email = ?",
            (email,),
        ).fetchone()
    return dict(row) if row else None


def upsert_account(
    email: str,
    channel_id: str,
    channel_title: str,
    avatar_url: str,
    refresh_token: str,
    db_path: Path | None = None,
) -> None:
    path = db_path or _db_path()
    _init(path)
    now = datetime.now(UTC).isoformat()
    with _connect(path) as conn:
        conn.execute(
            """
            INSERT INTO accounts (email, channel_id, channel_title, avatar_url, refresh_token, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(email) DO UPDATE SET
                channel_id = excluded.channel_id,
                channel_title = excluded.channel_title,
                avatar_url = excluded.avatar_url,
                refresh_token = excluded.refresh_token,
                updated_at = excluded.updated_at
            """,
            (email, channel_id, channel_title, avatar_url, refresh_token, now, now),
        )


def update_profile(
    email: str,
    channel_id: str,
    channel_title: str,
    avatar_url: str,
    db_path: Path | None = None,
) -> bool:
    path = db_path or _db_path()
    _init(path)
    with _connect(path) as conn:
        cur = conn.execute(
            "UPDATE accounts SET channel_id = ?, channel_title = ?, avatar_url = ? WHERE email = ?",
            (channel_id, channel_title, avatar_url, email),
        )
        return cur.rowcount > 0


def delete_account(email: str, db_path: Path | None = None) -> bool:
    path = db_path or _db_path()
    _init(path)
    with _connect(path) as conn:
        cur = conn.execute("DELETE FROM accounts WHERE email = ?", (email,))
        return cur.rowcount > 0