# OpenTaiko Asset Sources

This audit records OpenTaiko-related asset sources reviewed for future GDTaiko
skin, font, SFX, and song-pack work. It does not import any upstream assets.

Audit date: 2026-06-14

## Reviewed Sources

| Source | Commit | Candidate Assets | Evidence | Decision |
| --- | --- | --- | --- | --- |
| https://github.com/0auBSQ/OpenTaiko | 0ccf107c67c6a79828f54be0d6800047eb85f692 | bundled minimum assets, fonts, hit sounds | `LICENSE`, `README.md`, `OpenTaiko/Licenses/`, `OpenTaiko/Global/HitSounds/`, `OpenTaiko/Lang/` | Code is MIT. Bundled assets are mixed and require per-file review before import. |
| https://github.com/OpenTaiko/OpenTaiko-Skins | 00d78deb4ecfd01e1babcf85aace42dfd2c17bf5 | skins, fonts, menu SFX, character voices, global assets | `README.md`, `System/Open-World Memories/LICENSE.md`, `System/Open-World Memories/README.txt`, font license files, per-asset NOTICE files | Do not import skin, SFX, voice, or branded graphics without written permission or a clear asset-specific license. OFL font candidates may be imported separately if attribution is added. |
| https://github.com/OpenTaiko/OpenTaiko-Soundtrack | d10a60295d18fbc322ce7d6f72950ce9c9f5f530 | songs, jackets, `.tja` charts | `README.md` credits, chart license, reuploading section | Do not bundle songs, jackets, or media. Charts are CC-BY-4.0, but chart plus media redistribution requires separate permissions. |

## OpenTaiko Main Repository

The root `LICENSE` is MIT for the software source. The README states that songs,
skins, and different assets are now on separate repositories, and that only a
minimum asset set is provided for development purposes.

The README also states that OpenTaiko is open source code under MIT, but other
skins or song packages must follow their creators' licenses and rules, and that
the OpenTaiko license does not apply to those packages. GDTaiko must therefore
treat OpenTaiko as a behavior reference and cannot use the repository MIT license
as blanket permission for assets.

Observed asset paths that require separate review before import:

- `FDK/mplus-1p-medium.ttf`
- `OpenTaiko/Lang/font.ttf`
- `OpenTaiko/Lang/ja/NotoSansJP-Medium.ttf`
- `OpenTaiko/Lang/ja/NotoSansJP-Regular.ttf`
- `OpenTaiko/Lang/zh/SourceHanSansSC-Medium.otf`
- `OpenTaiko/Lang/zh/SourceHanSansSC-Regular.otf`
- `OpenTaiko/Global/HitSounds/Taiko/dong.wav`
- `OpenTaiko/Global/HitSounds/Taiko/ka.wav`
- `OpenTaiko/Global/HitSounds/Old Taiko/dong.ogg`
- `OpenTaiko/Global/HitSounds/Old Taiko/ka.ogg`

Current decision: local reference only. Do not copy bundled OpenTaiko assets into
GDTaiko unless an asset-level license and attribution path are recorded in
`docs/ASSET_AUDIT.md`.

## OpenTaiko-Skins

The repository README only describes the repository as OpenTaiko skins and global
assets for OpenTaiko Hub. It is not a repository-wide redistribution license.

The `System/Open-World Memories/LICENSE.md` file is an OpenTaiko-specific asset
license. It permits asset modification for OpenTaiko-related use, but forbids
commercial use outside listed exceptions, secondary distribution outside a direct
fork from the official OpenTaiko repository, and use not related to OpenTaiko
without written permission from the copyright holders. That does not permit
adapting the skin to GDTaiko.

Observed skin and graphics evidence:

- `System/Open-World Memories/README.txt` lists TJAPlayer3 default skin,
  Freepik patterns, cien assets, Waldo assets, and PNG Egg fireworks.
- `Global/PuchiChara/C01 - Tinyfox/NOTICE.txt` and the OutFox background notice
  state that Project OutFox branding or graphics are not permitted outside
  OpenTaiko without permission.

Audited skin candidate files:

| Path | Source URL | Author or Source | License or README Statement | Status |
| --- | --- | --- | --- | --- |
| `System/Open-World Memories/Graphics/5_Game/10_Effects/Hit/FireWorks.png` | https://github.com/OpenTaiko/OpenTaiko-Skins/blob/00d78deb4ecfd01e1babcf85aace42dfd2c17bf5/System/Open-World%20Memories/Graphics/5_Game/10_Effects/Hit/FireWorks.png | PNG Egg | `README.txt` credits PNG Egg for fireworks and marks the source non-commercial. | blocked |
| `System/Open-World Memories/Graphics/5_Game/20_Tower/Sky_Gradient.png` | https://github.com/OpenTaiko/OpenTaiko-Skins/blob/00d78deb4ecfd01e1babcf85aace42dfd2c17bf5/System/Open-World%20Memories/Graphics/5_Game/20_Tower/Sky_Gradient.png | Waldo, pressstart.vip assets | `README.txt` credits Waldo for tower result background and skyboxes; no reviewed file grants GDTaiko redistribution. | blocked |
| `System/Open-World Memories/Graphics/5_Game/10_Effects/Rainbow.png` | https://github.com/OpenTaiko/OpenTaiko-Skins/blob/00d78deb4ecfd01e1babcf85aace42dfd2c17bf5/System/Open-World%20Memories/Graphics/5_Game/10_Effects/Rainbow.png | cien, OpenTaiko Team | `README.txt` credits cien for rainbow result screen gauge and drum textures; OpenTaiko Extended License restricts non-OpenTaiko use without written permission. | blocked |
| `System/Open-World Memories/Graphics/5_Game/12_Lane/Red.png` | https://github.com/OpenTaiko/OpenTaiko-Skins/blob/00d78deb4ecfd01e1babcf85aace42dfd2c17bf5/System/Open-World%20Memories/Graphics/5_Game/12_Lane/Red.png | TJAPlayer3 default skin or OpenTaiko skin contributors | `README.txt` credits TJAPlayer3 default skin for in-game textures; no reviewed file grants GDTaiko redistribution. | blocked |
| `System/Open-World Memories/Graphics/5_Game/5_Background/Normal/Down/Outfox/NOTICE.txt` | https://github.com/OpenTaiko/OpenTaiko-Skins/blob/00d78deb4ecfd01e1babcf85aace42dfd2c17bf5/System/Open-World%20Memories/Graphics/5_Game/5_Background/Normal/Down/Outfox/NOTICE.txt | Project OutFox Developers | NOTICE says Project OutFox branding or graphics are not permitted outside OpenTaiko without permission. | blocked |

Current skin decision: blocked for import. These assets need written permission
or an asset-specific permissive license before use in GDTaiko.

Observed font candidates:

- `System/Open-World Memories/Fonts/MPLUSRounded1c-Medium.ttf`
- `System/Open-World Memories/Fonts/MPLUSRounded1c-Regular.ttf`
- `System/Open-World Memories/Fonts/ResourceHanRoundedCN-Medium.ttf`
- `System/Open-World Memories/Fonts/ResourceHanRoundedCN-Regular.ttf`
- `System/Open-World Memories/Fonts/ResourceHanRoundedKR-Medium.ttf`
- `System/Open-World Memories/Fonts/ResourceHanRoundedKR-Regular.ttf`
- `System/Open-World Memories/Fonts/Licenses/MPlusRounded1c.txt`
- `System/Open-World Memories/Fonts/Licenses/ResourceHanRounded.txt`

The bundled font license files identify M PLUS Rounded 1c and Resource Han
Rounded as SIL Open Font License 1.1 font software. These are candidate
repo-allowed assets, but they are not imported by this task. The reviewed OFL
text allows bundling and embedding with software, including commercial software,
provided the fonts are not sold by themselves, reserved font names are respected
for modified versions, and the OFL license text remains with the font software.
If imported later, copy the license text, add the font attribution entries listed
in `NOTICE.md`, and preserve OFL requirements.

Audited font candidate files:

| Path | Source URL | Author | License Statement | Embedding | NOTICE Target | Status |
| --- | --- | --- | --- | --- | --- | --- |
| `System/Open-World Memories/Fonts/MPLUSRounded1c-Medium.ttf` | https://github.com/OpenTaiko/OpenTaiko-Skins/blob/00d78deb4ecfd01e1babcf85aace42dfd2c17bf5/System/Open-World%20Memories/Fonts/MPLUSRounded1c-Medium.ttf | M PLUS Rounded 1c authors | `Fonts/Licenses/MPlusRounded1c.txt` says SIL Open Font License 1.1. | Allowed when bundled with software under OFL terms. | `NOTICE.md` Future Font Notices, M PLUS Rounded 1c | repo_allowed |
| `System/Open-World Memories/Fonts/MPLUSRounded1c-Regular.ttf` | https://github.com/OpenTaiko/OpenTaiko-Skins/blob/00d78deb4ecfd01e1babcf85aace42dfd2c17bf5/System/Open-World%20Memories/Fonts/MPLUSRounded1c-Regular.ttf | M PLUS Rounded 1c authors | `Fonts/Licenses/MPlusRounded1c.txt` says SIL Open Font License 1.1. | Allowed when bundled with software under OFL terms. | `NOTICE.md` Future Font Notices, M PLUS Rounded 1c | repo_allowed |
| `System/Open-World Memories/Fonts/ResourceHanRoundedCN-Regular.ttf` | https://github.com/OpenTaiko/OpenTaiko-Skins/blob/00d78deb4ecfd01e1babcf85aace42dfd2c17bf5/System/Open-World%20Memories/Fonts/ResourceHanRoundedCN-Regular.ttf | Cyano Hao and Adobe portions | `Fonts/Licenses/ResourceHanRounded.txt` says SIL Open Font License 1.1. | Allowed when bundled with software under OFL terms. | `NOTICE.md` Future Font Notices, Resource Han Rounded | repo_allowed |
| `System/Open-World Memories/Fonts/ResourceHanRoundedKR-Regular.ttf` | https://github.com/OpenTaiko/OpenTaiko-Skins/blob/00d78deb4ecfd01e1babcf85aace42dfd2c17bf5/System/Open-World%20Memories/Fonts/ResourceHanRoundedKR-Regular.ttf | Cyano Hao and Adobe portions | `Fonts/Licenses/ResourceHanRounded.txt` says SIL Open Font License 1.1. | Allowed when bundled with software under OFL terms. | `NOTICE.md` Future Font Notices, Resource Han Rounded | repo_allowed |

Observed SFX candidates:

- `System/Open-World Memories/Sounds/Cancel.ogg`
- `System/Open-World Memories/Sounds/Change.ogg`
- `System/Open-World Memories/Sounds/Clear.ogg`
- `System/Open-World Memories/Modules/Modal/Sounds/Coin.ogg`
- `Global/PuchiChara/01a - OpenTaiko-Kun/Welcome.ogg`
- `Archive/10 - AItritus/Welcome.ogg`

The Open-World Memories README credits menu SFX to Hitrison's menu SFX pack, but
no reviewed file in this repository provides enough redistribution and commercial
use terms for GDTaiko release inclusion. Character voice and welcome sounds also
lack a clear project-agnostic license in the reviewed files.

Audited SFX candidate files:

| Path | Source URL | Original Source | Author or Source | Rights Evidence | Attribution | Status |
| --- | --- | --- | --- | --- | --- | --- |
| `System/Open-World Memories/Sounds/Cancel.ogg` | https://github.com/OpenTaiko/OpenTaiko-Skins/blob/00d78deb4ecfd01e1babcf85aace42dfd2c17bf5/System/Open-World%20Memories/Sounds/Cancel.ogg | https://hitrison.itch.io/menu-sfx-pack | Hitrison | `README.txt` credits Hitrison menu SFX pack, but reviewed files do not state redistribution, modification, or commercial-use permission for GDTaiko. | Not sufficient for import. | blocked |
| `System/Open-World Memories/Sounds/Change.ogg` | https://github.com/OpenTaiko/OpenTaiko-Skins/blob/00d78deb4ecfd01e1babcf85aace42dfd2c17bf5/System/Open-World%20Memories/Sounds/Change.ogg | https://hitrison.itch.io/menu-sfx-pack | Hitrison | `README.txt` credits Hitrison menu SFX pack, but reviewed files do not state redistribution, modification, or commercial-use permission for GDTaiko. | Not sufficient for import. | blocked |
| `System/Open-World Memories/Modules/Modal/Sounds/Coin.ogg` | https://github.com/OpenTaiko/OpenTaiko-Skins/blob/00d78deb4ecfd01e1babcf85aace42dfd2c17bf5/System/Open-World%20Memories/Modules/Modal/Sounds/Coin.ogg | OpenTaiko-Skins repository | OpenTaiko skin contributors | No reviewed file states redistribution, modification, or commercial-use permission for GDTaiko. | Not sufficient for import. | blocked |
| `System/Open-World Memories/Sounds/HitSounds/Taiko/dong.ogg` | https://github.com/OpenTaiko/OpenTaiko-Skins/blob/00d78deb4ecfd01e1babcf85aace42dfd2c17bf5/System/Open-World%20Memories/Sounds/HitSounds/Taiko/dong.ogg | OpenTaiko-Skins repository | OpenTaiko skin contributors | No reviewed file states redistribution, modification, or commercial-use permission for GDTaiko. | Not sufficient for import. | blocked |
| `Global/PuchiChara/01a - OpenTaiko-Kun/Welcome.ogg` | https://github.com/OpenTaiko/OpenTaiko-Skins/blob/00d78deb4ecfd01e1babcf85aace42dfd2c17bf5/Global/PuchiChara/01a%20-%20OpenTaiko-Kun/Welcome.ogg | OpenTaiko-Skins repository | OpenTaiko community contributors | No reviewed file states redistribution, modification, or commercial-use permission for GDTaiko. | Not sufficient for import. | blocked |

Current SFX decision: blocked for import until upstream source and license terms
are verified per file.

## OpenTaiko-Soundtrack

The README contains song and chart credits, says `.tja` charts are licensed under
CC-BY-4.0, and states that permission is mandatory for reuploading OpenTaiko
charts alongside song files or media from song artists, jacket or BGA artists,
and collaboration staff where applicable.

Current soundtrack decision: blocked for bundled release. GDTaiko may support
user-local song folders, but must not bundle OpenTaiko songs, audio, jacket art,
or BGA media without per-file permission. If a chart-only compatibility fixture is
needed, create an original minimal fixture instead of copying a chart.
