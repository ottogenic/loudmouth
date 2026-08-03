# Classic Era Location Metadata

`Interface/AddOns/Loudmouth/ClassicMetadata.lua` stores English Classic Era
location data used by personality zone preferences.

- `ClassicZones`: all 46 vanilla outdoor/capital zone maps plus the three
  battleground maps, keyed by `UiMapID`.
- `ClassicInstances`: vanilla dungeons and raids that can be returned by
  `GetRealZoneText()`.
- `ClassicSubzones`: commonly surfaced `GetSubZoneText()` values grouped by
  parent zone. Parent scoping avoids collisions such as `Dun Algaz`.
- `ZoneRaceMetadata`: race associations with strengths from 1 (localized
  presence) to 3 (homeland or capital).
- `ZoneVibeMetadata`: environmental and thematic tags used by `likes.zones`
  and `hates.zones`.
- `SubzoneRaceMetadata` and `SubzoneVibeMetadata`: more-specific overrides for
  notable subzones.

Parent-zone tags describe conditions that are broadly true across the zone.
Localized features such as one cave, graveyard, dwarf outpost, demonic enclave,
or coastal settlement belong only to that parent-scoped subzone. Personality
authors use all matching liked and hated traits to write the dialogue for each
exact location; metadata tags are not generic runtime dialogue pools.

Zone and instance coverage is exhaustive for vanilla Classic Era. Subzone
coverage is comprehensive for normal outdoor, city, and notable interior play,
but Blizzard client data also contains duplicate, inaccessible, and seasonal
records that should not be treated as live `GetSubZoneText()` values.

Primary references:

- [UiMap, Classic Era 1.15.9](https://wago.tools/db2/UiMap/csv?build=1.15.9.68940)
- [AreaTable, Classic Era 1.15.9](https://wago.tools/db2/AreaTable/csv?build=1.15.9.68940)
- [WMOAreaTable, Classic Era 1.15.9](https://wago.tools/db2/WMOAreaTable/csv?build=1.15.9.68940)
- [GetRealZoneText](https://warcraft.wiki.gg/wiki/API_GetRealZoneText)
- [GetSubZoneText](https://warcraft.wiki.gg/wiki/API_GetSubZoneText)
- [Questie ZoneDB](https://github.com/Questie/Questie/blob/master/Database/Zones/zoneDB.lua)
