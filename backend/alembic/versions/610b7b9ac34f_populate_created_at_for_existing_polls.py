"""populate created_at for existing polls

Revision ID: 610b7b9ac34f
Revises: 77b1ddd79d7c
Create Date: 2026-01-30 17:54:57.691311

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '610b7b9ac34f'
down_revision: Union[str, Sequence[str], None] = '77b1ddd79d7c'
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    """Populate created_at for existing polls."""
    op.execute("UPDATE polls SET created_at = NOW() WHERE created_at IS NULL")


def downgrade() -> None:
    """Downgrade schema."""
    # This is a data-only migration. A downgrade could set the values back to NULL,
    # but that might not be desirable. We'll leave it as a no-op.
    pass
