/**
    Main file for the Locked Archive project -- EASY instance.

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
:- ['instances/instance_easy.pl'].

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
%   ?- initialize(evaluator).   % MANDATORY before first run
%   ?- main.                    % interactive controller picker
%   ?- main(simple).            % or directly: control_simple
%   ?- main(reactive).          % or directly: control_reactive
%
% Reasoning tasks (course-standard, once initialize(evaluator) has run):
%
%   Legality -- indigolog/1 takes the action sequence in NATURAL order
%   (first action executed first), exactly as you'd write it:
%     ?- indigolog([pick_up(key1,r1), unlock_with_key(l1,key1), move(r1,r2,l1),
%                   read_clue(l2,r2), unlock_with_code(l2), move(r2,r3,l2)]).
%
%   Projection -- eval/3 takes the action sequence in REVERSED order
%   (most recently executed action FIRST -- mirrors do(a,s) nesting).
%   This is the opposite convention from indigolog/1 above, and easy to
%   get backwards: the SAME 6-action plan as above, reversed, checking
%   at(r3) holds at the end:
%     ?- eval(at(r3),
%             [move(r2,r3,l2), unlock_with_code(l2), read_clue(l2,r2),
%              move(r1,r2,l1), unlock_with_key(l1,key1), pick_up(key1,r1)],
%             true).
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% EOF
