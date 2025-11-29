# Patience GUI

Desktop application for Patience chatbot testing framework built with Electron and React.

## What is this?

This is a **native desktop application**, not a browser-based app. It uses Electron (Chromium + Node.js) to provide a graphical interface for Patience.

**Development vs Production:**

- **Development Mode**: Uses a local Vite dev server (localhost:5173) for hot reload while coding. The Electron window loads from this server for fast iteration.
- **Production Mode**: Completely standalone desktop app. No server needed. The UI is bundled into the application.

**It's a real desktop app:**
- ✅ Runs as native application (not in browser)
- ✅ Has its own window, icon, menu bar
- ✅ Direct file system access
- ✅ Distributable as `.dmg`, `.exe`, `.AppImage`
- ✅ Works offline
- ✅ Appears in Applications folder / Start Menu

The localhost server is **only** used during development for convenience. The final packaged app is completely standalone.

## Installation

```bash
# Install all dependencies (including GUI)
npm install
```

## Running the GUI

### Development Mode

```bash
npm run dev:gui
```

This will:
1. Start the Vite dev server (React UI)
2. Launch Electron with the GUI
3. Enable hot reload for development

The GUI will open automatically. Any changes to the React code will hot reload.

### Production Build

```bash
# Build GUI components
npm run build:gui

# Package for distribution
npm run package

# Platform-specific builds
npm run package:mac     # macOS
npm run package:win     # Windows
npm run package:linux   # Linux
```

Built applications will be in `dist-electron/`.

## Using the GUI

### Live Testing

1. **Load or Create Configuration**
   - Click "Show Config" to open the JSON editor
   - Use "Load Example" to load a sample configuration
   - Or "Open" to load your own config file
   - Edit the JSON directly in the Monaco editor

2. **Run Tests**
   - Click "Run Tests" to execute your test scenarios
   - Watch real-time progress in the status indicator
   - View console output at the bottom
   - See results summary when complete

3. **Save Configuration**
   - Click "Save" to save your config to a file
   - Configurations are standard JSON files

### Features

- **Split View**: Toggle config editor on/off
- **Real-time Validation**: JSON errors shown immediately
- **Progress Tracking**: See which scenarios are running
- **Console Output**: Live logs during test execution
- **Results Summary**: Pass/fail counts and timing

## Project Structure

```
gui/
├── main/           # Electron main process (Node.js)
│   ├── index.ts    # Main entry point
│   └── ipc-handlers.ts  # IPC communication handlers
├── preload/        # Preload scripts (security bridge)
│   └── index.ts
├── renderer/       # React UI (Chromium)
│   ├── src/
│   │   ├── App.tsx
│   │   ├── pages/
│   │   ├── components/
│   │   └── store/
│   └── index.html
└── shared/         # Shared types
    └── types.ts
```

## Development

### File Structure

- `gui/main/` - Electron main process (Node.js backend)
- `gui/renderer/` - React UI (frontend)
- `gui/preload/` - Security bridge between main and renderer
- `gui/shared/` - Shared TypeScript types

### Making Changes

1. **UI Changes**: Edit files in `gui/renderer/src/`
   - Changes hot reload automatically
   - No restart needed

2. **Backend Changes**: Edit files in `gui/main/`
   - Requires Electron restart
   - Stop and run `npm run dev:gui` again

3. **IPC Changes**: Edit `gui/main/ipc-handlers.ts` and `gui/preload/index.ts`
   - Update both files to add new IPC channels
   - Restart Electron

### Adding New Features

1. Add IPC handler in `gui/main/ipc-handlers.ts`
2. Expose in preload script `gui/preload/index.ts`
3. Use in React components via `window.patienceAPI`

## Troubleshooting

### GUI won't start

1. Make sure dependencies are installed:
   ```bash
   npm install
   ```

2. Check that ports are available (Vite uses 5173)

3. Try cleaning and rebuilding:
   ```bash
   rm -rf node_modules dist dist-gui
   npm install
   npm run build
   npm run build:gui
   ```

### Tests won't run

1. Verify your configuration is valid JSON
2. Check that your target bot endpoint is accessible
3. Look at console output for error messages

### Monaco editor not loading

1. Check browser console for errors
2. Ensure `@monaco-editor/react` is installed
3. Try clearing cache and restarting

## Features

### Phase 1 (Current)
- ✅ Basic Electron + React setup
- ✅ Live Testing UI
- ✅ Config editor with Monaco
- ✅ Test execution with progress
- ✅ Real-time console output

### Phase 2 (Planned)
- ⏳ Log Analysis UI
- ⏳ Adversarial Testing UI
- ⏳ Report viewer

### Phase 3 (Planned)
- ⏳ Settings/Preferences
- ⏳ Template library
- ⏳ Enhanced error handling

## Technology Stack

- **Electron** - Desktop app framework
- **React** - UI framework
- **TypeScript** - Type safety
- **Vite** - Build tool and dev server
- **Tailwind CSS** - Styling
- **Monaco Editor** - Code editor
- **Zustand** - State management
- **React Query** - Async state management

## Security

The app uses Electron's security best practices:
- Context isolation enabled
- Node integration disabled
- Sandbox enabled
- Preload script for safe IPC

## Distribution

Built apps will be available in `dist-electron/`:
- **macOS**: `.dmg` and `.zip`
- **Windows**: `.exe` installer and portable
- **Linux**: `.AppImage`, `.deb`, and `.rpm`
