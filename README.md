# Norse Tree Builder

A city builder game themed around Norse mythology, where you manage a growing tree. The game is built with Godot Engine 4.4 and uses a 16-bit pixel art style in a 3D environment with billboarded models.

## Game Concept

- Start with a seed that falls from the sky
- Watch as the tree grows over time
- Manage different sections of the tree (roots, trunk, branches)
- Consider weight distribution on limbs
- Trim the tree to maintain its health and shape

## Technical Features

- Procedurally generated tree growth
- Billboarded 2D sprites in a 3D environment
- Camera rotation around the central tree
- Dictionary-based component system for tree parts

## Project Structure

- `scenes/`: Contains all scene files
  - `main.tscn`: Main game scene
  - `tree_parts/`: Individual tree components (seed, roots, trunk, branches)
- `scripts/`: Contains all GDScript files
  - `main.gd`: Main game logic
  - `camera_controller.gd`: Handles camera movement
  - `billboard.gd`: Makes sprites face the camera

## Next Steps

1. Add proper sprite textures for tree components
2. Implement tree trimming mechanics
3. Add weight simulation for branches
4. Create UI for player interaction
5. Implement Norse mythology elements and progression
