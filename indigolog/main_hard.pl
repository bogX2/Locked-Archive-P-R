/**
    Main file for the Locked Archive project -- HARD instance.

    Follows the same load pattern as the course's own main_01.pl
    (elevator example): it loads the "plain" IndiGolog interpreter
    (no environment manager / external devices needed, since this
    domain is purely simulated) and then the application files.

    This file must be placed so that config.pl (defining dir/2 and
    interpreter/1) is loaded FIRST. On the course VM this typically
    means either:
      (a) copying/symlinking this whole indigolog/ folder into
          <indigolog-main>/examples/locked_archive/, then running:
              swipl <indigolog-main>/config.pl main_easy.pl
      (b) or, if config.pl auto-loads relative to itself, running
          swipl from inside <indigolog-main>/examples/locked_archive/
              swipl ../../config.pl main_easy.pl
    Check config.pl's own header comments on the VM for the exact
    invocation it expects (see main.pl / main_01.pl in the course
    examples for the exact convention used there).
**/

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% CONSULT NECESSARY FILES
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% top-level interpreter (interpreter/1 is defined in config.pl)
:- dir(indigolog_plain, F), consult(F).

% domain + controllers + this instance
:- ['escape_room_domain.pl'].
:- ['controllers.pl'].
:- ['instances/instance_hard.pl'].

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% MAIN PREDICATE -- evaluate this to run the demo (course-style menu)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

main :-
    findall(C, proc(control(C), _), L),
    repeat,
    format('Controllers available: ~w\n', [L]),
    write('Select controller: '),
    read(S), nl,
    member(S, L),
    format('Executing controller: *~w*\n', [S]), !,
    indigolog(control(S)).

main(C) :- indigolog(control(C)).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Usage (from a fresh swipl session, AFTER config.pl + this file loaded):
%
%   ?- initialize.      % MANDATORY before first run (NOT initialize(evaluator))
%   ?- main.                    % interactive controller picker
%   ?- main(simple).            % or directly: control_simple
%   ?- main(reactive).          % or directly: control_reactive
%
% Reasoning tasks (course-standard, once initialize has run):
%
%   This is the WEST branch (17 actions, cost 13, the PDDL-optimal
%   route -- requires the mandatory combine puzzle). The EAST branch
%   (12 actions, cost 16, no combine) is also legal -- see RESULTS.md.
%
%   Legality -- indigolog/1 takes the action sequence in NATURAL order
%   (first action executed first), exactly as you'd write it:
%     ?- indigolog([pick_up(key_start,r1), unlock_with_key(l0,key_start), move(r1,r2,l0), pick_up(key_w1,r2), unlock_with_key(l_w1,key_w1), move(r2,r3,l_w1), pick_up(item_p,r3), read_clue(l_w2,r3), unlock_with_code(l_w2), move(r3,r4,l_w2), pick_up(item_q,r4), combine(item_p,item_q,key_w3), unlock_with_key(l_w3,key_w3), move(r4,r5,l_w3), read_clue(l_w4,r5), unlock_with_code(l_w4), move(r5,r8,l_w4)]).
%
%   Projection -- eval/3 takes the action sequence in REVERSED order
%   (most recently executed action FIRST -- mirrors do(a,s) nesting).
%   The SAME 17-action plan as above, reversed, checking at(r8) holds:
%     ?- holds(at(r8), [move(r5,r8,l_w4), unlock_with_code(l_w4), read_clue(l_w4,r5), move(r4,r5,l_w3), unlock_with_key(l_w3,key_w3), combine(item_p,item_q,key_w3), pick_up(item_q,r4), move(r3,r4,l_w2), unlock_with_code(l_w2), read_clue(l_w2,r3), pick_up(item_p,r3), move(r2,r3,l_w1), unlock_with_key(l_w1,key_w1), pick_up(key_w1,r2), move(r1,r2,l0), unlock_with_key(l0,key_start), pick_up(key_start,r1)]).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EOF
