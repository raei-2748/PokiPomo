# Focus Timer Screen

## Gentle/Standard Mode
```
[Muted greyscale starscape, occasional twinkles]

      Standard Mode
        ────────

         ┏━━━━━━━┓
        ╱         ╲
       ╱    🌙     ╲    ← Central moon/planet
      ╱             ╲
     ╱    35:42      ╱   ← Time remaining
     ╲               ╱
      ╲             ╱
       ╲___________╱

[Orbital progress line: 60% complete arc]

[Small cosmic spirit, powered down, dim glow]

         ⏸ Pause
     (Gentle: direct pause)
   (Standard: "Are you sure?")
```

## Strict Mode
```
[Pure greyscale, no extra animations]

        Strict Mode
         ────────

         ┏━━━━━━━┓
        ╱         ╲
       ╱    🌑     ╲    ← Darker moon
      ╱             ╲
     ╱    35:42      ╱   ← Time only
     ╲               ╱
      ╲             ╱
       ╲___________╱

[Simple progress arc, no embellishments]

[Cosmic spirit completely dormant]

      No pause option
      ─────────────
```

### Design Specifications:
- **Central Timer**: Large circular moon/planet design
- **Progress Indicator**: Orbital line that completes the circle
- **Time Display**: Large, clear monospace font (48px)
- **Background**: Subtle starfield with minimal movement
- **Enforcement Display**: Mode indicator at top
- **Mascot State**: Dim/sleeping during all focus sessions

### Interaction Notes:
- Timer updates every second
- Gentle mode: Direct pause access
- Standard mode: Confirmation dialog for pause
- Strict mode: No pause option available
- Orbital progress smoothly animates
- No mid-session rewards or distractions