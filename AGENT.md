# NoxxLFGClassic - WoW Addon Development Guide

## Build/Lint/Test Commands
- **No build system**: This is a WoW addon - files are loaded directly by the game client
- **Test in-game**: Load addon in WoW Classic and test with `/nlfg` command
- **Lua diagnostics**: VS Code Lua extension provides linting (configured in .vscode/settings.json)
- **Validation**: Check .toc file loads correctly and all dependencies resolve

## Architecture & Structure
- **Main entry**: NoxxLFGClassic.lua (core addon logic, UI, event handling)
- **Functions**: funcs/nlfgfuncs.lua (utility functions and role checking)
- **Libraries**: lib/ contains LibDBIcon, LibUIDropDownMenu, LibStub dependencies
- **Assets**: images/ for UI icons and graphics
- **Configuration**: .toc file defines interface version, dependencies, and load order
- **Data storage**: Uses WoW SavedVariables (NoxxLFGSettings, NoxxLFGListings, NoxxLFGSetRole)

## Code Style & Conventions
- **Lua 5.1**: Target runtime for WoW Classic
- **Global namespace**: Use `NoxxLFGClassic` table for addon functions
- **Naming**: camelCase for variables, PascalCase for functions
- **Colors**: Hex color codes with pipe notation (e.g., `|cFFFCC453`)
- **WoW API**: Extensive use of WoW global functions and frames
- **Comments**: ASCII art headers, descriptive function comments
- **Diagnostic**: `---@diagnostic disable: undefined-field` used for WoW globals
