"""Metadata indexing and search services."""
from __future__ import annotations

from collections import defaultdict
from dataclasses import dataclass, field
from typing import Dict, Iterable, List, Optional

from sqlalchemy import select
from sqlalchemy.orm import Session

from .models import Asset, MetadataEntry


@dataclass
class MetadataIndex:
    """In-memory index for metadata search."""

    by_type: Dict[str, List[int]] = field(default_factory=lambda: defaultdict(list))
    by_tag: Dict[str, List[int]] = field(default_factory=lambda: defaultdict(list))
    assets: Dict[int, Asset] = field(default_factory=dict)

    def index_asset(self, asset: Asset) -> None:
        self.assets[asset.id] = asset
        self.by_type[asset.asset_type].append(asset.id)
        for entry in asset.metadata_entries:
            tag_key = f"{entry.key}:{entry.value}".lower()
            self.by_tag[tag_key].append(asset.id)

    def clear(self) -> None:
        self.by_type.clear()
        self.by_tag.clear()
        self.assets.clear()

    def search(
        self,
        *,
        asset_type: Optional[str] = None,
        tag_filters: Optional[Iterable[str]] = None,
        text: Optional[str] = None,
    ) -> List[Asset]:
        candidates: List[int]
        if asset_type:
            candidates = list(self.by_type.get(asset_type, []))
        else:
            candidates = list(self.assets.keys())

        if tag_filters:
            tag_sets = [set(self.by_tag.get(tag.lower(), [])) for tag in tag_filters]
            if tag_sets:
                intersect = set(candidates)
                for tag_set in tag_sets:
                    intersect &= tag_set
                candidates = list(intersect)

        if text:
            text_lower = text.lower()
            candidates = [
                asset_id
                for asset_id in candidates
                if text_lower in self.assets[asset_id].name.lower()
                or any(text_lower in entry.value.lower() for entry in self.assets[asset_id].metadata_entries)
            ]

        return [self.assets[candidate] for candidate in candidates]


class MetadataService:
    """Service that orchestrates metadata indexing and searching."""

    def __init__(self) -> None:
        self._index = MetadataIndex()

    def rebuild_index(self, session: Session) -> None:
        assets = session.execute(select(Asset)).scalars().unique().all()
        self._index.clear()
        for asset in assets:
            # ensure metadata entries are loaded
            _ = asset.metadata_entries
            self._index.index_asset(asset)

    def search(
        self,
        session: Session,
        *,
        asset_type: Optional[str] = None,
        tags: Optional[List[str]] = None,
        text: Optional[str] = None,
    ) -> List[Asset]:
        if not self._index.assets:
            self.rebuild_index(session)
        return self._index.search(asset_type=asset_type, tag_filters=tags, text=text)

    def add_metadata(self, session: Session, metadata: MetadataEntry) -> None:
        asset = session.get(Asset, metadata.asset_id)
        if asset:
            session.refresh(asset)
            self._index.index_asset(asset)


metadata_service = MetadataService()
