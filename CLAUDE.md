# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Ruby client gem for the [Sprites API](https://sprites.dev) - a platform for creating stateful sandbox environments.

## Commands

```bash
# Run all tests
rake test

# Run a single test file
ruby -Ilib:test test/sprites/test_client.rb

# Run a specific test method
ruby -Ilib:test test/sprites/test_client.rb -n test_method_name
```

## Architecture

This gem uses a **client-resource pattern**:

- **`Sprites::Client`** - HTTP client using Faraday with Bearer token auth
- **`Sprites::Resources::*`** - API endpoint namespaces (Sprites, Checkpoints)
- **`Sprites::Collection`** - Pagination wrapper with continuation token support
- **`Sprites::Sprite`** - Data model representing a sprite instance

### Request Flow

```
Client → Resource → Faraday HTTP → Sprites API
```

Resources call client methods (`get`, `post`, `put`, `delete`, `post_stream`) which handle:
- Bearer token authentication
- JSON serialization/deserialization
- Error handling (wraps in `Sprites::Error`)
- NDJSON streaming for long-running operations (checkpoints)

### Adding New Endpoints

1. Create resource class in `lib/sprites/resources/`
2. Add accessor method to `Client`
3. Add tests with VCR cassettes in `test/sprites/`

