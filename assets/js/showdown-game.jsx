import React from 'react';
import ReactDOM from 'react-dom';
import _ from 'lodash';

export default function game_init(root, channel) {
    ReactDOM.render(<Showdown channel={channel}/>, root);
}
let teams = false; // teams yet to be implemented

class Showdown extends React.Component {
    constructor(props) {
        super(props);
        this.channel = props.channel;
        this.state = {};
        this.text = "";

        this.channel
            .join()
            .receive("ok", this.got_view.bind(this))
            .receive("error", resp => {
                console.log("Unable to join", resp);
            });

        this.channel.on("move", this.receive_broadcast.bind(this));
        this.channel.on("join", this.receive_broadcast.bind(this));
    }

    got_view(view) {
        let game = view.game;
        game.text = "";
        if (game.opponent) {
            game.player.hp = game.player.current_pokemon.hp;
            game.opponent.hp = game.opponent.current_pokemon.hp;
        }
        this.setState(game);

        if (game.finished) {
            setTimeout(() => {
                this.endGame();
            }, 10000);
        }

        if (game.sequence && game.sequence.length > 0) {
            this.animate();
        }
    }

    endGame() {
        this.channel.push("end")
            .receive("ok", () => {});
        window.location.href = "/";
    }

    animate() {
        let state = _.assign({}, this.state);
        let seq1 = state.sequence[0];
        let text1 = seq1.player + "'s " + seq1.attacker + " used " + seq1.move + " on " + seq1.opponent + "'s " + seq1.recipient + "!";
        let recipient1 = state.player.name !== seq1.player ? "player" : "opponent";
        let seq2 = state.sequence[1];

        // sets the displayed text to the first event text
        this.setState({text: text1});
        delay(3000).then(() => {

            // sets the recipient's (player's or opponent's) hp value to remaining hp
            let p1 = _.assign({}, this.state[recipient1], {hp: seq1.opponent_remaining_hp});
            this.setState({[recipient1]: p1});
            return delay(1000);
        }).then(() => {

            if (state.sequence.length > 1) {
                let text2 = seq2.player + "'s " + seq2.attacker + " used " + seq2.move + " on " + seq2.opponent + "'s " + seq2.recipient + "!";
                let recipient2 = state.player.name === seq1.player ? "player" : "opponent";
                let p2 = _.assign({}, this.state[recipient2], {hp: seq2.opponent_remaining_hp});

                // reset the battle text component, so it gets the typewriter animation again
                this.setState({text: ""});
                // and same thing for the 2nd event
                this.setState({text: text2});

                delay(3000).then(() => {
                    this.setState({[recipient2]: p2});
                    return delay(1000);
                }).then(() => {
                    this.channel.push("apply")
                        .receive("ok", this.got_view.bind(this));
                });
            } else {
                this.channel.push("apply")
                    .receive("ok", this.got_view.bind(this));
            }
        });

    }

    receive_broadcast(msg) {
        this.setState(_.assign({}, this.state, msg));
        this.channel.push("view")
            .receive("ok", this.got_view.bind(this));
    }

    selectMove(move) {
        this.channel.push("move", {move: move})
            .receive("ok", this.got_view.bind(this));
    }


    render() {
        let finishScreen =  <div>
            <p>You {this.state.finished}!</p>
        </div>;

        let waitingRoom = <div className="waiting-room">
            Waiting for another user to join.
        </div>;

        let gameFullScreen = <div>This game is currently full.</div>;

        if (this.state.opponent) {
            if (!this.state.finished) {
                return <Battle text={this.text}
                               state={this.state}
                               selectMove={this.selectMove.bind(this)} />;
            } else {
                return finishScreen;
            }
        } else {
            if (this.state.player) {
                return waitingRoom;
            } else {
                return gameFullScreen;
            }
        }
    }
}

function Battle(props) {
        let player = () => props.state.player;
        let opponent = () => props.state.opponent;
        let text = () => props.state.text;
        let selectMove = props.selectMove;

        return <div className="battle">

                <Team name={player().name}
                      team={player().team}
                      classname="player" />

                <Team name={opponent().name}
                      team={opponent().team}
                      classname="opponent" />

                <div className="artwork player">
                    <img src={"../images/" + player().current_pokemon.name + ".png"} />
                </div>

                <PkmInfoBar owner={player()} classname="player" />
                <PkmInfoBar owner={opponent()}  classname="opponent" />

                <div className="artwork opponent">
                    <img src={"../images/" + opponent().current_pokemon.name + ".png"} />
                </div>

                { text() && <div className="battle-text typewriter">{text()}</div>}
                {props.state.sequence.length === 0 && teams &&
                    <Menu team={player().team}
                          moves={player().current_pokemon.moves}
                          selectMove={selectMove} />}
                {props.state.sequence.length === 0 && !teams &&
                    <Moveset classname="menu"
                             moves={player().current_pokemon.moves}
                             selectMove={selectMove} />}
                {props.state.sequence.length > 0 && <div className="menu"></div>}
            </div>;
}

function PkmInfoBar(props) {
        let pokemon = props.owner.current_pokemon || "";
        let hp = props.owner.hp;
        let c = props.classname + " info-bar";

        return <div className={c}>
            <div className="name">{pokemon.name}</div>
            <div className="pkm-hp">{hp} / {pokemon.max_hp}</div>
        </div>;
}

class Moveset extends React.Component {
    constructor(props) {
        super(props);
        this.state = { enabled: true};
        this.moves = props.moves;
        this.class = props.classname + " moveset";
        this.state = {enabled: true};
    }

    selectMove(move) {
        this.setState({enabled: false});
        this.props.selectMove(move);
    }

    render() {
        let moves = _.map(this.moves, (move) => {
            return <Move key={move.name}
                         move={move}
                         selectMove={this.selectMove.bind(this)} />
        });

        return <div className={this.class}>
            {this.state.enabled && moves}
        </div>;
    }
}

function Move(props) {
    let move = props.move;
    let c = props.classname + " move " + move.type;

    let handleClick = function(move) {
        props.selectMove(move);
    };

    return <div className={c} onClick={(e) => handleClick(move.name)}>
                <div className="name">{move.name}</div>
                <div className="move-info">
                    <div className="move-type">{move.type}</div>
                    <div className="move-power">power: {move.power}</div>
                </div>
            </div>;
}

function Team(props) {
    let c = props.classname + " team";
    return <div className={c}>
                <div className="name">
                    {props.name}
                </div>
            </div>;
}

class Menu extends React.Component {
    constructor(props) {
        super(props);
        this.channel = props.channel;
        this.state = {
            menu: ''
        };
        this.team = props.team;
        this.moves = props.moves;
    }

    handleClick(text) {
        this.setState({menu: text});
    }

    render() {
        return <div className="menu">
            {this.state.menu !== '' &&
                <button onClick={(e) => this.handleClick('')}>
                    back to menu
                </button>}
            <div className="submenu">
                {this.state.menu === '' &&
                    <button onClick={ (e) => this.handleClick('moves')}>
                        moves
                    </button>}
                {teams && this.state.menu === '' &&
                    <button onClick={ (e) => this.handleClick('pokemon')}>
                        pokemon
                    </button>}
                {this.state.menu === 'moves' &&
                    <Moveset moves={this.moves}
                             selectMove={this.props.selectMove} />}
                {this.state.menu === 'pokemon'  &&
                    <SwitchPkm team={this.team} />}
            </div>
        </div>;
    }
}

function delay(time) {
    return new Promise( r => {
        setTimeout(r, time);
    });
}