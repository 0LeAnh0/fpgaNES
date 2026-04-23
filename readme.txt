# NES FPGA UVM Verification Summary

## 1) Scope
This project currently has block-level UVM verification for:
- `nes_ram` (WRAM + VRAM)
- `ppu_ri`
- `ppu_bg`
- `ppu_spr`
- `ppu_vga`
- `ppu_top` integration

Project root:
`D:\Project Vivado\nesfpga`

Main simulator flow:
- QuestaSim
- UVM 1.1d
- Makefile-driven regression

## 2) Current Verification Architecture
Common UVM structure used across blocks:
- sequence item
- sequencer / sequences
- driver
- monitor
- subscriber / coverage
- scoreboard with embedded reference model
- env
- package

Top-level testbench integration is handled in:
`nes_fpga.srcs/sim_1/imports/src/nes_tb_top.sv`

## 3) Verification Status by Block

### 3.1) NES_RAM - Completed
Primary regression:
- `nes_ram_regression_test`

Verified behaviors:
- WRAM mirror
- WRAM/VRAM alias
- data patterns
- boundary walk
- full sweep
- zero-page / stack traffic
- initial reset
- random reset pulses

Latest result:
- `UVM_ERROR = 0`
- `RAM_COV = 100.00%`
- `WRAM = 100.00%`
- `VRAM = 100.00%`

### 3.2) PPU_RI - Completed
Key tests:
- `ppu_ri_full_regression_test`
- `ppu_ri_signoff_test`
- `ppu_ri_scroll_signoff_test`

Verified behaviors:
- `$2000-$2007` register path
- `$2005/$2006` two-write latch behavior
- `$2007` buffered read
- `$2007` increment side-effects
- `$2004` OAM read/write path
- scroll register mapping
- initial reset
- random reset stress

Latest result:
- `ppu_ri_full_regression_test: PASS=342 FAIL=0`
- `ppu_ri_signoff_test: PASS=261 FAIL=0`
- `PPU_RI_COV = 91.25%`

### 3.3) PPU_BG - Completed
Key tests:
- `ppu_bg_pixel_test`
- `ppu_bg_full_regression_test`

Verified behaviors:
- NT/AT/PT0/PT1 fetch rhythm
- VRAM address generation
- scroll propagation from RI
- enable/disable path
- pixel output checking
- clip behavior
- reset handling in TB/model
- reset stress during active rendering

Latest result:
- `ppu_bg_pixel_test: PASS=2772 FAIL=0`
- `ppu_bg_full_regression_test: PASS=7784 FAIL=0`
- `BG_COV = 95.93%`

### 3.4) PPU_SPR - Completed
Key tests:
- `ppu_spr_full_regression_test`
- `ppu_spr_full_frame_test`

Verified behaviors:
- OAM access
- sprite evaluation
- fetch phase
- render output
- force-hit path
- overflow exercise
- random reset stress
- full-frame scenario

Latest result:
- `ppu_spr_full_regression_test: PASS=1758050 FAIL=0`
- `SPR_COV = 100.00%`

### 3.5) PPU_VGA - Completed
Key tests:
- `ppu_vga_reset_test`
- `ppu_vga_palette_visible_area_test`
- `ppu_vga_border_color_test`
- `ppu_vga_vblank_timing_test`
- `ppu_vga_full_regression_test`

Verified behaviors:
- 1-cycle RGB delay
- visible-area palette decoding
- border color forcing
- `pix_pulse_out`
- `vblank_out` set/clear timing
- reset sanity

Latest result:
- `ppu_vga_full_regression_test: PASS`
- `VGA_COV = 100.00%`
- `VGA_SCB_RPT: PASS=26626128 FAIL=0`

### 3.6) PPU Full Integration - Completed
Top-level integration test:
- `ppu_full_integration_test`

Verified integration paths:
- `RI -> PRAM -> top palette mux -> VGA RGB`
- `RI -> OAM -> SPR request -> top VRAM arbiter`
- `RI -> OAM -> SPR overflow observed through the integrated top path`
- `RI vblank + NMI enable -> top /VBL output`
- live PRAM update during active display
- NMI enable/disable toggled during active vblank
- initial reset at top level before traffic starts
- top-level testcase headers and filtered logging so integration log is not flooded by RI internal info

Architecture note:
- integration no longer reuses `ppu_ri_base_test`
- it now uses dedicated `ppu_top_base_test`
- `ppu_top_env` owns RI stimulus agents plus top monitor / top coverage / top scoreboard
- top test now uses a log catcher to suppress low-value RI internal `UVM_INFO` during integration runs

Latest result:
- `UVM_ERROR = 0`
- `PPU_TOP_COV = 88.43%`
- `PPU_TOP_SCB_RPT: PASS=9589785 FAIL=0`

## 4) Full Regression Strategy
In this project, `full_regression_test` means:
- one aggregated signoff-style run for a block
- not a test class calling other test classes directly
- instead, it combines the main directed/stress scenarios for that block into one run

Current aggregated regressions:
- `nes_ram_regression_test`
- `ppu_ri_full_regression_test`
- `ppu_bg_full_regression_test`
- `ppu_spr_full_regression_test`
- `ppu_vga_full_regression_test`
- `ppu_full_integration_test`

## 5) Known Remaining Coverage Gaps

### NES_RAM
- No meaningful open functional gap in current scope.
- Coverage is already full for WRAM and VRAM.

### PPU_RI
- Coverage is `91.25%`.
- Remaining gap is mainly rare protocol ordering / register combination depth.
- No open checker bug remains in `$2007`.

### PPU_BG
- Coverage is `95.93%`.
- Main gap is now broader long-run combination depth rather than a known missing core scenario.
- Key improvement made:
  - impossible `clip_on + non_zero_palette` cross bins were excluded
  - full regression now includes targeted corners for vblank / pre-render / scroll extremes

### PPU_SPR
- Coverage is `100.00%`.
- No meaningful open gap remains in the current `PPU_SPR` scope.
- Key improvement made:
  - overflow is now exercised correctly in both `8x8` and `8x16`
  - `nes_y_next_in` in the overflow sequence was aligned with the DUT's next-scanline evaluation semantics

### PPU_VGA
- Coverage is `100.00%`.
- No meaningful open gap remains in the current VGA scope.
- Key improvement made:
  - the visible-only palette cross no longer counts non-visible bins that the design does not meaningfully exercise

### PPU_TOP Integration
- Coverage is `88.43%`.
- Current integration focuses on high-value subsystem paths, not on duplicating block-level signoff coverage.
- Important interpretation:
  - `PPU_TOP_COV` is subsystem coverage
  - it does not replace `PPU_RI_COV`, `BG_COV`, `SPR_COV`, or `VGA_COV`
- Current integration now includes:
  - palette path to VGA
  - live PRAM update during active display
  - sprite arbiter ownership
  - sprite overflow observed through the top path
  - `/VBL` gate and live NMI-enable race handling
- Future expansion could add:
  - more BG/SPR overlap cases
  - sprite priority / primary interaction at top level
  - longer frame-boundary scenarios
  - more PRAM mirror / palette interaction at subsystem level

## 6) Technical Verification Notes to Remember
This section captures testbench practices that are important even when they do not show up as active bugs.

### 6.1) Reset must be owned and observed explicitly
What to remember:
- do not assume reset is “naturally correct” just because DUT state looks fine in one run
- a reusable base test should own reset application and should also check post-reset observable state

How it was handled here:
- block regressions include `initial reset` and, where useful, `random reset stress`
- top integration also starts with an explicit reset-observe case before functional traffic begins
- reset intent is placed in reusable base-test helpers instead of leaving each test to do ad-hoc reset sequencing

Why it matters:
- if reset ownership is unclear, later tests may pass accidentally depending on startup state

### 6.2) Sampling edge and DUT update edge are not the same thing
What to remember:
- monitor sampling through clocking blocks usually sees a timed view of the interface, not raw zero-delay combinational truth
- combinational outputs often need either delayed compare or a carefully chosen sampling point

How it was handled here:
- BG checking uses delayed prediction
- VGA checking is written with awareness of the 1-cycle RGB register delay
- RI buffered-read checking pairs protocol events instead of assuming one-cycle alignment
- monitor/checker timing was chosen based on when the DUT output becomes meaningful, not just on the first visible signal toggle

Why it matters:
- many false mismatches in UVM come from timing capture assumptions, not from DUT bugs

### 6.3) Scoreboards should model protocol meaning, not only signal value
What to remember:
- if a feature has side-effects, buffering, or multi-step writes, a scoreboard must track transaction meaning
- simple same-cycle value compare is often not enough

How it was handled here:
- RI scoreboard models `$2005/$2006` latch behavior and `$2007` buffered-read semantics
- top scoreboard models palette path, VRAM arbitration, and `/VBL` gating
- BG and VGA scoreboards also use output-aware prediction instead of raw same-cycle mirror compare

Why it matters:
- a scoreboard that is too shallow will either miss real bugs or create noisy false fails

### 6.4) Integration env should own integration intent clearly
What to remember:
- a top-level integration test should read like a top-level test
- if architecture reuses a sub-block base too directly, future debugging becomes harder

How it was handled here:
- integration was refactored to `ppu_top_base_test`
- `ppu_top_env` now owns RI stimulus plus top-level monitor / coverage / scoreboard
- log filtering suppresses RI internal info so top-level intent stays readable
- RI remained the realistic stimulus path, but ownership moved under the top env so the architecture stays subsystem-oriented

Why it matters:
- clean ownership makes debug, maintenance, and review much easier later

### 6.4B) Top coverage should stay subsystem-focused
What to remember:
- top-level coverage should measure subsystem behavior
- detailed block coverage should remain a block-level responsibility

How it was handled here:
- `PPU_RI_COV`, `BG_COV`, `SPR_COV`, and `VGA_COV` remain the detailed signoff metrics
- `PPU_TOP_COV` only tracks integration-relevant behavior such as arbitration, palette muxing, `/VBL` gating, and top-observed sprite overflow
- when subsystem intent expanded, the top test and top covergroup were extended directly instead of copying block coverpoints upward

Why it matters:
- keeping block and subsystem metrics separate makes review clearer and makes remaining gaps easier to classify correctly

### 6.5) Logging should be intentional, not automatic
What to remember:
- simulator logs, diagnostic files, and transcripts multiply quickly in verification projects
- default flow should stay clean; extra logs should be opt-in

How it was handled here:
- RAM file logging was disabled by default
- `sim_diag.log` is now opt-in with `+TB_DIAG_LOG=1`
- Makefile flow removes temporary logs unless `KEEP_LOGS=1`
- transcript output is redirected away in the standard flow
- debug helpers were kept available, but moved behind explicit switches so normal regression stays clean

Why it matters:
- if logging is uncontrolled, the workspace becomes noisy and real debug signals become harder to find

### 6.6) Classify outputs before writing checkers
What to remember:
- one of the easiest ways to create false failures is to treat every output as if it were sampled the same way
- some outputs are effectively combinational from the DUT point of view
- others are registered and therefore must be checked against delayed state

How it was handled here:
- VGA checking explicitly accounts for the 1-cycle RGB delay
- BG checking uses delayed prediction instead of immediate compare
- RI `$2007` checking was fixed by pairing transactions semantically rather than assuming same-cycle data meaning
- checker logic was written only after separating “decode happens now” from “observable output becomes valid later”

Why it matters:
- if the checker is written before the signal timing model is understood, the testbench can fail even when the DUT is correct

### 6.7) Timeout must match the time scale of the feature being tested
What to remember:
- not every block should use the same timeout philosophy
- register interface tests, pixel path tests, scanline tests, and full-frame tests all need different run budgets

How it was handled here:
- VGA tests were given enough runtime to reach visible area and vblank set/clear coordinates
- SPR full-frame regression was allowed to span frame-level behavior
- top integration timeout was sized to observe top-level vblank and inter-block activity cleanly
- base tests were adjusted so long-running timing tests do not inherit unrealistically short limits from fast register tests

Why it matters:
- a timeout that is too short creates false failures that look like DUT bugs but are really testbench configuration mistakes

### 6.8) Force, release, and debug hooks should be controlled carefully
What to remember:
- force/release is useful, but if used without discipline it can hide real DUT behavior
- debug hooks and diagnostic taps should not stay permanently active in the normal flow

How it was handled here:
- top-level diagnostics were changed to opt-in behavior
- integration keeps debug intent centralized instead of scattering hooks across multiple layers
- standard flow avoids automatic transcript and extra debug-file generation
- debug control was moved to explicit knobs in the TB and Makefile rather than always-on behavior hidden in the environment

Why it matters:
- controlled debug hooks make the environment easier to trust, easier to review, and easier to reuse later

## 7) Technical Challenges Encountered and How They Were Resolved
This section records the more important engineering challenges that came up during the work.
The focus here is on verification meaning, timing, architecture, and debugability rather than tool noise.

### 7.1) RI `$2007` buffered-read could not be checked correctly with shallow same-order pairing
Technical challenge:
- `$2007` is not a plain same-cycle read path
- it involves buffered-read semantics, address side-effects, and interaction between master-side register activity and slave-side VRAM data return

What made it risky:
- a checker can look “almost right” for most traffic and still be wrong on interleaved address/update sequences
- pairing transactions by arrival order is not strong enough for this protocol

How it was resolved:
- scoreboard pairing was changed to follow protocol meaning rather than simple first-in-first-out arrival assumptions
- slave monitor sampling was moved to a more stable observation point
- the reference read buffer was preserved correctly across `$2006` activity

Technical takeaway:
- whenever a register path includes internal buffering or delayed data visibility, the checker must model protocol intent, not just signal chronology

### 7.2) BG verification was initially stronger on fetch/address behavior than on final pixel truth
Technical challenge:
- background pipelines are easy to verify at the address-generation level but harder to prove at the final rendered-pixel level

What made it risky:
- a testbench can pass while only proving the fetch schedule is plausible
- bugs in palette selection, delayed pixel composition, or clip behavior can remain hidden if only `vram_a_out` is checked deeply

How it was resolved:
- a dedicated `ppu_bg_pixel_test` was added
- pixel-accuracy intent was pulled into the full regression flow
- scoreboard prediction was strengthened around rendered output rather than only fetch path legality

Technical takeaway:
- for render blocks, address/fetch correctness and pixel correctness should be treated as separate proof obligations

### 7.3) SPR signoff needed explicit reset and frame-boundary thinking, not just functional scenarios
Technical challenge:
- sprite logic is not only about OAM access and render output
- it is also sensitive to reset points, evaluation phase boundaries, overflow handling, and behavior across a frame

What made it risky:
- a regression can contain many useful sequences and still miss the exact moments where state should clear or roll over

How it was resolved:
- reset stress was folded into the aggregated regression path
- overflow exercise was made more explicit
- full-frame intent was preserved as a real part of the signoff direction rather than a side scenario

Technical takeaway:
- for frame-based graphics blocks, phase transitions and frame boundaries deserve explicit test intent, not just incidental coverage

### 7.3B) SPR overflow depended on next-scanline semantics, not only on sprite count
Technical challenge:
- the DUT decides whether a sprite is in range using `nes_y_next_in`
- a sequence can place more than 8 sprites on one apparent Y line and still miss overflow if it does not present the next-scanline value the way the DUT expects

What made it risky:
- the old overflow sequence looked plausible by inspection
- coverage stayed open even though the regression already contained explicit overflow scenarios

How it was resolved:
- the overflow sequence was rewritten so `nes_y_next_in` carries the next-scanline value across the full evaluation window
- overflow is now exercised in both `8x8` and `8x16`
- this closed `cp_overflow` and `cross_size_overflow` while keeping the scoreboard green

Technical takeaway:
- whenever a graphics pipeline reasons about "next line" or "next phase", the sequence must drive that semantic value consistently across the whole evaluation interval

### 7.4) VGA and BG checking both required deliberate treatment of timing visibility
Technical challenge:
- not every output is observable in the same temporal way
- some values are meaningful immediately as combinational decode, while others are only meaningful after a register stage

What made it risky:
- treating all outputs as same-cycle comparable creates false fails that look exactly like DUT bugs

How it was resolved:
- VGA checking was written with explicit awareness of the 1-cycle RGB delay
- BG checking used delayed prediction to line up monitor observation with meaningful output timing
- monitor/checker assumptions were anchored to “when the output becomes valid” rather than “when the signal first wiggles”

Technical takeaway:
- one of the most important early TB tasks is to classify each observed output as combinational-view, registered-view, or protocol-delayed-view

### 7.4B) Some low coverage came from unreachable cross bins, not weak stimulus
Technical challenge:
- coverage can stay low even when regression quality is already good if the model counts cross bins that the DUT can never hit meaningfully

What made it risky:
- this can push the team toward unnatural stimulus just to chase percentage
- it also hides whether a gap is a real verification hole or only a coverage-model issue

How it was resolved:
- `PPU_BG` excluded the impossible `clip_on + non_zero_palette` cross expectation
- `PPU_VGA` limited palette crossing to visible-area sampling only
- after that, coverage increased in a way that better matched actual design intent

Technical takeaway:
- before adding more tests, always ask whether every uncovered bin is truly reachable and functionally meaningful

### 7.5) Integration worked functionally before it was architecturally clear
Technical challenge:
- a top-level test can function while still being architecturally confusing
- reusing a sub-block base test too directly makes ownership blurry and slows later debug

What made it risky:
- reviewers and future maintainers may misread the test as “RI plus extras” rather than a true subsystem environment
- log output and debug ownership become harder to reason about

How it was resolved:
- integration was refactored into `ppu_top_base_test` plus `ppu_top_env`
- RI agents stayed as the realistic stimulus path, but ownership moved under the top environment
- top-level monitor, coverage, and scoreboard were made explicit subsystem assets

Technical takeaway:
- in subsystem verification, architectural clarity is itself a technical requirement because it directly affects debug speed and reuse quality

### 7.6) Integration readability required active control of log ownership
Technical challenge:
- once RI stimulus is embedded inside the top environment, RI internal messages can dominate the transcript

What made it risky:
- a correct integration run can still be difficult to review if the log reads like a sub-block debug session instead of a top-level test

How it was resolved:
- low-value RI internal `UVM_INFO` messages were filtered during integration runs
- top-level case headers and subsystem-level result messages were kept visible

Technical takeaway:
- readable logs are not just cosmetic; they are part of making subsystem verification scalable for review and debug

### 7.7) Timeout strategy had to follow the physical time scale of each block
Technical challenge:
- register tests, pixel tests, scanline tests, and frame-level tests live on very different simulation time scales

What made it risky:
- using one generic timeout philosophy across all blocks creates false failures in long-timing blocks or wastes runtime in short-latency blocks

How it was resolved:
- VGA tests were given enough simulation budget to reach visible and vblank timing points
- SPR full-frame behavior was allowed to complete naturally
- top integration timeout was sized to observe top-level timing events and cross-block interactions

Technical takeaway:
- timeout is part of the verification model; it should be chosen from the behavior being proven, not copied blindly between blocks

### 7.8) Clean debugability required debug hooks and extra logs to become opt-in
Technical challenge:
- verification environments naturally accumulate transcripts, debug logs, diagnostic files, and local print helpers over time

What made it risky:
- once those hooks become always-on, the environment becomes noisier, harder to trust, and harder to hand off

How it was resolved:
- diagnostics were moved behind explicit enable switches
- extra RAM file logging was disabled by default
- transcript and temporary log behavior were cleaned in the normal flow

Technical takeaway:
- debug infrastructure should exist, but it should behave like a controlled instrument panel, not like permanent background noise

## 8) Important Paths
- `nes_fpga.srcs/sim_1/imports/src/tst/ram/nes_ram_regression_test.sv`
- `nes_fpga.srcs/sim_1/imports/src/tst/ppu_ri/ppu_ri_full_regression_test.sv`
- `nes_fpga.srcs/sim_1/imports/src/tst/ppu_bg/ppu_bg_full_regression_test.sv`
- `nes_fpga.srcs/sim_1/imports/src/tst/ppu_spr/ppu_spr_full_regression_test.sv`
- `nes_fpga.srcs/sim_1/imports/src/tst/ppu_vga/ppu_vga_full_regression_test.sv`
- `nes_fpga.srcs/sim_1/imports/src/tst/ppu_top/ppu_top_base_test.sv`
- `nes_fpga.srcs/sim_1/imports/src/tst/ppu_top/ppu_full_integration_test.sv`
- `nes_fpga.srcs/sim_1/imports/src/env/ppu_top_env.sv`
- `nes_fpga.srcs/sim_1/imports/src/chk/ppu_top_scoreboard.sv`
- `nes_fpga.srcs/sim_1/imports/src/nes_tb_top.sv`
- `Makefile`

## 9) How to Run
From Git Bash in project root:

- `make questa TEST=nes_ram_regression_test`
- `make questa TEST=ppu_ri_full_regression_test`
- `make questa TEST=ppu_bg_full_regression_test`
- `make questa TEST=ppu_spr_full_regression_test`
- `make questa TEST=ppu_vga_full_regression_test`
- `make questa TEST=ppu_full_integration_test`

## 10) Current Signoff View
Current practical status:
- block-level regressions are green
- top-level PPU integration regression is green
- no known open functional failure remains in the verified scope
- remaining work is mostly coverage-depth expansion, not active red bugs
