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

        this.channel
            .join()
            .receive("ok", this.got_view.bind(this))
            .receive("error", resp => {
                console.log("Unable to join", resp);
            });

        this.channel.on("move", this.receive_broadcast.bind(this));
    }

    got_view(view) {
        let game = view.game;
        console.log(game);
        this.setState(game);

        if ("sequence" in game) {
            if (game.sequence.length === 2) {
                setTimeout(() => {
                    this.channel.push("apply")
                        .receive("ok", this.got_view.bind(this))
                }, 1000);
            }
        }
    }

    receive_broadcast(msg) {
        this.setState(_.assign({}, this.state, msg));
        this.channel.push("view")
            .receive("ok", this.got_view.bind(this));
        console.log(msg);
    }

    selectMove(move) {
        console.log("Submitted move: " + move);
        this.channel.push("move", {move: move})
            .receive("ok", this.got_view.bind(this));
    }

    render() {
        return <div>
            { debug && <RestartButton></RestartButton>}
            { !this.state.opponent && <WaitingRoom></WaitingRoom> }
            { this.state.opponent && <Battle state={this.state} selectMove={this.selectMove.bind(this)}></Battle> }

        </div>
    }
}

class WaitingRoom extends React.Component {
    constructor(props) {
        super(props);
        this.channel = props.channel;
        this.state = {};
    }
    render() {
        return <div className="waiting-room">Waiting for another user to join.</div>
    }
}

class Battle extends React.Component {
    constructor(props) {
        super(props);
        this.channel = props.channel;
        this.player = props.state.player;
        this.opponent = props.state.opponent;
        this.selectMove = props.selectMove;
    }

    render() {
        return <div className="battle">
    { teams && <Team name={this.player.name} team={this.player.team} classname="player"></Team> }
    { teams && <Team name={this.opponent.name} team={this.opponent.team} classname="opponent"></Team> }
                <img className="artwork player" src="https://cdn.discordapp.com/attachments/405465305822003201/546814731944591371/image0.jpg"></img>
                <PkmInfoBar pokemon={this.player.current_pokemon} classname="player"></PkmInfoBar>
                <PkmInfoBar pokemon={this.opponent.current_pokemon}  classname="opponent"></PkmInfoBar>
                <img className="artwork opponent" src="https://cdn.discordapp.com/attachments/405465305822003201/546814731944591371/image0.jpg"></img>
                { true && <BattleText></BattleText>}
                <Menu team={this.player.team} moves={this.player.current_pokemon.moves} selectMove={this.selectMove}></Menu>
            </div>
    }
}

class PkmInfoBar extends React.Component {
    constructor(props) {
        super(props);
        this.state = {};
        this.pokemon = props.pokemon;
        this.class = this.props.classname + " info-bar";

    }
    render() {
        return <div className={this.class}>
            <div className="pkm-name">{this.pokemon.name}</div>
            <div className="pkm-hp">{this.pokemon.hp} / {this.pokemon.max_hp}</div>
        </div>
    }
}

class Moveset extends React.Component {
    constructor(props) {
        super(props);
        this.state = {};
        this.moves = props.moves;
    }
    render() {
        return <div className="moveset">
            <Move move={this.moves[0]} className="move-1" selectMove={this.props.selectMove}></Move>
            <Move move={this.moves[1]}  className="move-2" selectMove={this.props.selectMove}></Move>
        </div>
    }
}

class Move extends React.Component {
    constructor(props) {
        super(props);
        this.channel = props.channel;
        this.state = {};
        this.class = this.props.classname + " move";
        this.move = props.move;

    }

    handleClick(move) {

        // this.channel.push("move", {move: this.move})
        //     .receive("ok", )
        // this.props.selectMove(move)
        this.props.selectMove(move);
        // TODO: send move to server
    }

    render() {
        return <div className={this.class} onClick={(e) => this.handleClick(this.move.name)}>
            <div className="move-name">{this.move.name}</div>
            <div className="move-info">
                <div className="move-type">{this.move.type}</div>
                <div className="move-power">power: {this.move.power}</div>

            </div>

        </div>
    }

}
// class Result extends React.Component {
//     constructor(props) {
//         super(props);
//         this.channel = props.channel;
//         this.state = {};
//     }
//     // result + button to redirect to / ?
//     render() {
//         return <div className="redirect">

//         </div>
//     }
// }

class Team extends React.Component {
    constructor(props) {
        super(props);
        this.channel = props.channel;
        this.state = {};
        this.class = this.props.classname + " team";
    }

    render() {
        return <div className={this.class}></div>
    }
}

class BattleText extends React.Component {

    constructor(props) {
        super(props);
        this.channel = props.channel;
        this.state = {};
        this.class = "battle-text";
    }

    render() {
        return <div className={this.class}></div>
    }
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
        console.log(this.state);
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

class RestartButton extends React.Component {
    constructor(props) {
        super(props);
    }
    // insert restart button here for debug purposes
    render() {
        return <button></button>
    }
}

class SwitchPkm extends React.Component {
    constructor(props) {
        super(props);
    }

    render() {
        return <div></div>
    }
}