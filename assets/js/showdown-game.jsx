import React from 'react';
import ReactDOM from 'react-dom';
import _ from 'lodash';

export default function game_init(root, channel) {
    ReactDOM.render(<Showdown channel={channel}/>, root);
}
let debug = false;
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
        game.player.hp = game.player.current_pokemon.hp;
        game.opponent.hp = game.opponent.current_pokemon.hp;
        console.log(game);
        this.setState(game);
        let sequence = game.sequence;
        if (sequence) {
            if (sequence.length === 2) {
                this.animate(game);
                
            }
        }
    }

    animate() {
        let state = _.assign({}, this.state);
        let seq1 = state.sequence[0];
        let text1 = seq1.player + "'s " + seq1.attacker + " used " + seq1.move + " on " + seq1.opponent + "'s " + seq1.recipient + "!";
        let recipient1 = state.player.name != seq1.player ? "player" : "opponent";
        let seq2 = state.sequence[1];
        this.setState({text: text1});

        delay(3000).then(() => {
            let p1 = _.assign({}, this.state[recipient1], {hp: seq1.opponent_remaining_hp});
            this.setState({[recipient1]: p1});
            return delay(1000);
        }).then(() => {
            if (seq2) {
                let text2 = seq2.player + "'s " + seq2.attacker + " used " + seq2.move + " on " + seq2.opponent + "'s " + seq2.recipient + "!";
                let recipient2 = state.player.name == seq1.player ? "player" : "opponent";
                let p2 = _.assign({}, this.state[recipient2], {hp: seq2.opponent_remaining_hp});
                this.setState({text: ""});
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
        console.log("broadcast received", msg);
        this.setState(_.assign({}, this.state, msg));
        this.channel.push("view")
            .receive("ok", this.got_view.bind(this));
    }

    selectMove(move) {
        // console.log("Submitted move: " + move);
        this.channel.push("move", {move: move})
            .receive("ok", this.got_view.bind(this));
    }


    render() {
        return <div>
            { !this.state.opponent && <WaitingRoom></WaitingRoom> }
            { this.state.opponent && !this.state.finished && <Battle text={this.text} state={this.state} selectMove={this.selectMove.bind(this)}></Battle> }
            { this.state.finished && <div>You {this.state.finished}!</div>}
        </div>
    }
}

function WaitingRoom(props) {
    return <div className="waiting-room">Waiting for another user to join.</div>;
}

class Battle extends React.Component {
    constructor(props) {
        super(props);
        this.channel = props.channel;
        this.state = {};
        this.player = () => this.props.state.player;
        this.opponent = () => this.props.state.opponent;
        this.text = () => this.props.state.text;
        this.selectMove = props.selectMove;
    }

    render() {
        return <div className="battle">
                <Team name={this.player().name} team={this.player().team} classname="player"></Team> 
                <Team name={this.opponent().name} team={this.opponent().team} classname="opponent"></Team> 
                <div className="artwork player">
                    <img className={this.state.playerShake} src={"../images/" + this.player().current_pokemon.name + ".png"}></img>
                </div>
                <PkmInfoBar owner={this.player()} classname="player"></PkmInfoBar>
                <PkmInfoBar owner={this.opponent()}  classname="opponent"></PkmInfoBar>
                <div className="artwork opponent">
                    <img className={this.state.opponentShake} src={"../images/" + this.opponent().current_pokemon.name + ".png"}></img>
                </div>

                { this.text() && <BattleText text={this.text()}></BattleText>}
                {this.props.state.sequence.length == 0 && teams && <Menu team={this.player().team} moves={this.player().current_pokemon.moves} selectMove={this.selectMove}></Menu>}
                {this.props.state.sequence.length == 0 && !teams && <Moveset classname="menu" moves={this.player().current_pokemon.moves} selectMove={this.selectMove}></Moveset>}
                {this.props.state.sequence.length > 0 && <div className="menu"></div>}
            </div>
    }
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
        console.log(this.state);
        this.moves = props.moves;
        this.class = props.classname + " moveset";
    }

    selectMove(move) {
        this.setState({enabled: false});
        this.props.selectMove(move);
    }

    render() {
        let moves = [];
            for (let i = 0; i < this.moves.length; i++) {
                let move = moves[i];
                moves.push(
                    <Move key={i} move={this.moves[i]} selectMove={this.selectMove.bind(this)}></Move>
                );
            }
        return <div className={this.class}>
            {this.state.enabled && moves}
        </div>
    }
}

function Move(props) {
    let c = props.classname + " move";
    let move = props.move;

    
    let handleClick = function(move) {
        props.selectMove(move);
    }

return <div className={c} onClick={(e) => handleClick(move.name)}>
    <div className="name">{move.name}</div>
    <div className="move-info">
        <div className="move-type">{move.type}</div>
        <div className="move-power">power: {move.power}</div>

    </div>
</div>;
}

class Team extends React.Component {
    constructor(props) {
        super(props);
        this.channel = props.channel;
        this.state = {};
        this.class = this.props.classname + " team";
    }

    render() {
        return <div className={this.class}>
            <div className="name">
                {this.props.name}
            </div>
        </div>
    }
}

function BattleText(props) {
    return <div className="battle-text typewriter">{props.text}</div>;
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
        {this.state.menu != '' && <button onClick={ (e) => this.handleClick('')}>back to menu</button>}
        <div className="submenu">
            {this.state.menu == '' && <button onClick={ (e) => this.handleClick('moves')}>moves</button>}
            {teams && this.state.menu == '' && <button onClick={ (e) => this.handleClick('pokemon')}>pokemon</button>}
            {this.state.menu == 'moves' && <Moveset moves={this.moves} selectMove={this.props.selectMove}></Moveset>}
            {this.state.menu == 'pokemon'  && <SwitchPkm team={this.team}></SwitchPkm>}</div>
        </div>
    }
}


class SwitchPkm extends React.Component {
    constructor(props) {
        super(props);
        this.updateView = props.updateView;
    }

    render() {
        return <div></div>
    }
}

function delay(time) {
    return new Promise( r => {
        setTimeout(r, time);
    });
}