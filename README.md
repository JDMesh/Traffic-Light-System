# Two-Way Traffic Light System - RZ301 EP4CE6

A complete traffic light controller implementation for the Altera Cyclone EP4CE6 FPGA board with integrated 7-segment display timer.

## System Overview

### Traffic Light Controller
- **8-state machine** running at ~100Hz (12.5ms per state)
- **Direction 1**: RED (37.5ms) → YELLOW (12.5ms) → GREEN (37.5ms)
- **Direction 2**: GREEN (37.5ms) → YELLOW (12.5ms) → RED (37.5ms)
- Mutually exclusive directions (prevents collision)
- Total cycle: ~100ms

### 7-Segment Display
- **Multiplexed 4-digit display** on board
- Shows elapsed **seconds (0-59)**
- Continuously scans DIG1 (tens) and DIG2 (ones)
- DIG3 and DIG4 unused
- 1kHz refresh rate for flicker-free display

### Clock Distribution
- **50MHz input** from board (Pin E3 = CLK0)
- Dividers:
  - 50MHz → 100Hz (traffic light state machine)
  - 50MHz → 1Hz (seconds counter)
  - 50MHz → 1kHz (7-segment multiplexing)

## Hardware Connections

### Traffic Light LEDs (with 220Ω resistors)
```
RED1_LED    → Pin 3   (LED0) → Breadboard + 220Ω → GND
GREEN1_LED  → Pin 2   (LED1) → Breadboard + 220Ω → GND
YELLOW1_LED → Pin 141 (LED3) → Breadboard + 220Ω → GND
RED2_LED    → Pin 1   (LED2) → Breadboard + 220Ω → GND
GREEN2_LED  → Pin 136 (GPIO) → Breadboard + 220Ω → GND
```

### Reset & Clock
```
CLK0    → Pin E3 (50MHz clock)
rst_btn → Pin A6 (Active LOW - push = reset)
```

### 7-Segment Display (Board integrated)
- Segment pins: D2, E2, D1, C1, B1, A1, F2 (segments a-g)
- Digit select: G2, H2, H1, G1 (DIG1-DIG4)
- **Common Anode**: Pull digit high (1) to enable, segments low (0) to light

## Files

| File | Purpose |
|------|----------|
| `traffic_light_top.v` | Top-level module with clock dividers, state machine & display driver |
| `traffic_light_tb.v` | Testbench for simulation |
| `ep4ce6_pin_assignment.ucf` | FPGA pin constraints |
| `README.md` | This file |

## Simulation Steps

1. **Open Quartus II**
2. **Create New Project** for EP4CE6
3. **Add Files**:
   - `traffic_light_top.v`
4. **Set Top Level**: `traffic_light_top`
5. **Run Testbench**:
   - Tools → Run Simulation (EDA)
   - Select `traffic_light_tb.v`
   - Simulate for ~10µs to see full cycle
6. **Observe**:
   - State transitions 0→7→0
   - RED1/GREEN1/YELLOW1/RED2/GREEN2 outputs
   - Seconds counter incrementing
   - 7-segment digit outputs

## Programming the Board

1. **Compile** (Tools → Compile Design)
2. **Import Pin Assignment**: 
   - Assignments → Import Assignments
   - Select `ep4ce6_pin_assignment.ucf`
3. **Generate Bitstream**
4. **Program** via USB-Blaster
5. **Connect LEDs** to breadboard:
   - LED anodes (long leg) → FPGA pins
   - LED cathodes (short leg) → 220Ω resistor → GND
6. **Power on** and observe:
   - Traffic lights cycling in opposite directions
   - 7-segment display counting seconds (0-59)
   - Reset button (Pin A6) resets everything

## Timing Breakdown

| Component | Frequency | Period |
|-----------|-----------|--------|
| CLK0 (input) | 50MHz | 20ns |
| Traffic state | ~100Hz | 10ms |
| Seconds counter | 1Hz | 1s |
| 7-seg scan | 1kHz | 1ms |
| Direction GREEN phase | N/A | 37.5ms (3 states) |
| Direction YELLOW phase | N/A | 12.5ms (1 state) |
| Full cycle | N/A | ~100ms (8 states) |

## State Machine Details

```
State | RED1 | GREEN1 | YELLOW1 | RED2 | GREEN2 | Duration
------|------|--------|---------|------|--------|----------
000   |  1   |   0    |    0    |  0   |   1    | 12.5ms (DIR1: RED, DIR2: GREEN)
001   |  1   |   0    |    0    |  0   |   1    | 12.5ms
010   |  1   |   0    |    0    |  0   |   1    | 12.5ms
011   |  0   |   0    |    1    |  0   |   0    | 12.5ms (YELLOW transition)
100   |  0   |   1    |    0    |  1   |   0    | 12.5ms (DIR1: GREEN, DIR2: RED)
101   |  0   |   1    |    0    |  1   |   0    | 12.5ms
110   |  0   |   1    |    0    |  1   |   0    | 12.5ms
111   |  0   |   0    |    1    |  0   |   0    | 12.5ms (YELLOW transition)
------|------|--------|---------|------|--------|----------
Total cycle: ~100ms
```

## Notes

- **220Ω Resistors**: Provides proper current limiting for standard LEDs (~20mA @ 5V)
- **Pin 136 for GREEN2**: Verify this is available on your specific board; adjust if needed
- **7-segment pins**: Match with your actual board schematic if different from UCF
- **Active-low reset**: Button press (LOW signal) triggers reset
- **Common Anode display**: Active HIGH on digit select, active LOW on segments
- **Seconds counter**: Wraps to 0 after 59 seconds
- **Safety**: Prevents RED and GREEN from being simultaneously active on same direction

## Testing Checklist

- [ ] Simulation shows state cycling 0→7→0
- [ ] Traffic light LEDs cycle in correct pattern
- [ ] Opposite directions never both GREEN simultaneously
- [ ] YELLOW light appears during transitions
- [ ] Seconds counter increments every second
- [ ] 7-segment displays show 00-59
- [ ] Reset button forces state to 000 and seconds to 00
- [ ] All 5 LEDs light correctly on breadboard

## Troubleshooting

### Lights not working:
- Check 220Ω resistor connections
- Verify pin assignments in UCF file
- Ensure cathodes connected to GND through resistor

### 7-segment display not showing:
- Verify segment pins in UCF match board schematic
- Check digit select pins are toggling at 1kHz
- Ensure Common Anode jumper is set correctly on board

### Timing issues:
- Verify 50MHz clock is present on Pin E3
- Check clock divider logic in `traffic_light_top.v`
- Run simulation to verify clock dividers work

## License

Free to use and modify for educational purposes.