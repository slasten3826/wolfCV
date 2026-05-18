# Evidence Guard Report

- claim_id: claim-002
  status: SUPPORTED
  review_required: false
  reason: Draft wording matches evidence ev-002 exactly, which lists the same commands in a CLI prototype.
  recommended_wording: Developed a CLI prototype with commands including snapshot, interaction, advance, events, draw, latent_trump_closure, scenario, autoplay, headless, play, smoke, and bench.
  blocking_evidence_ids: ev-002

- claim_id: claim_001
  status: SUPPORTED
  review_required: false
  reason: Draft wording fully supported by strong evidence ev_cli_main_entry describing CLI entry point with game state initialization and event descriptions.
  recommended_wording: Developed a CLI entry point for a card game that initializes game state and handles event descriptions for commit_manifest, arm_hand, and other events.
  blocking_evidence_ids: ev_cli_main_entry

- claim_id: claim-007
  status: UNSUPPORTED
  review_required: true
  reason: Draft text describes a 'game state inspection module that produces textual snapshots', but the claim's own safer_wording and the only supporting evidence (ev_glyphs_shapes) concern Love2D glyph rendering. The draft wording is not supported by any available evidence.
  recommended_wording: Defined Love2D functions to render operator glyphs (FLOW downward triangle, MANIFEST upward triangle, trigrams) using polygon, line, and rectangle primitives.
  blocking_evidence_ids: ev_glyphs_shapes

- claim_id: claim_game_state_validation_32
  status: PARTIALLY_SUPPORTED
  review_required: false
  reason: Draft wording matches evidence ev_invariants_lua, but evidence is medium confidence with limitations (only covers defined invariants, not all possible corruptions). The claim's own support_level is PARTIALLY_SUPPORTED.
  recommended_wording: The artifact defines a set of invariant-checking functions for a simulated game state, including checks for board closure, zone hole absence, trump consistency, and trump card classification.
  blocking_evidence_ids: ev_invariants_lua

- claim_id: claim_scenario_simulation_35
  status: SUPPORTED
  review_required: false
  reason: Draft wording exactly matches strong evidence ev_scenarios_draw_once, which confirms the draw_once function recording top card and hand/flow sizes.
  recommended_wording: The scenarios.lua module provides a draw_once function that records the top card before draw and the hand/flow sizes before and after drawing.
  blocking_evidence_ids: ev_scenarios_draw_once

- claim_id: claim_general_70
  status: SUPPORTED
  review_required: false
  reason: Draft wording is fully supported by evidence ev_cli_bench_findings_001, which confirms 1000/1000 smoke bench passes and the interpretation of latent_trump_closure failing cases as normal machine property.
  recommended_wording: A limited-duration smoke bench run (1000 iterations) showed no invariant failures, with failing cases in the latent_trump_closure bench interpreted as normal machine property rather than errors.
  blocking_evidence_ids: ev_cli_bench_findings_001

