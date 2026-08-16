# Banana Escape Asset Export Specs

These specs are set up so generated assets can drop into Flutter + Flame with minimal cleanup.

## General Rules

- Format: PNG
- Background: transparent
- Color space: sRGB
- Padding: leave 8-12% empty space around the sprite
- Lighting: top-left
- Shadow: soft baked contact shadow only if it does not exceed sprite bounds too much

## Character

- Idle / front gameplay pose: 1024 x 1024
- Left lean: 1024 x 1024
- Right lean: 1024 x 1024
- Hit pose: 1024 x 1024
- Magnet pose: 1024 x 1024
- Character should occupy roughly 72-80% of canvas height

## Obstacles

- Banana peel: 768 x 768
- Crate: 768 x 768
- Cart: 896 x 896
- Rock: 768 x 768
- Pit: 1024 x 768
- Smoothie box: 768 x 768

## Collectibles

- Coin: 512 x 512
- Combo banana: 512 x 512
- Magnet: 512 x 512

## Vehicle

- Blender truck gameplay rear view: 1024 x 1024
- Blender truck menu/key art: 1536 x 1536

## UI / Branding

- App icon source: 1024 x 1024
- Play Store icon export: 512 x 512
- Feature art/key visual: 2048 x 1024
- Menu splash illustration: 1600 x 900

## Naming Convention

- `banana_idle.png`
- `banana_left.png`
- `banana_right.png`
- `banana_hit.png`
- `banana_magnet.png`
- `obstacle_peel.png`
- `obstacle_crate.png`
- `obstacle_cart.png`
- `obstacle_rock.png`
- `obstacle_pit.png`
- `obstacle_smoothie_box.png`
- `coin_banana.png`
- `combo_banana.png`
- `powerup_magnet.png`
- `truck_blender_rear.png`

## Fast Integration Tip

If the tool generates multiple strong versions, keep version suffixes until final selection:

- `banana_idle_v1.png`
- `banana_idle_v2.png`
- `banana_idle_v3.png`

Then rename the chosen version to the canonical filename before import.
