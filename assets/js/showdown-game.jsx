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
        this.state = {
            users: [],
            submitted_moves: []
        };
        this.channel
            .join()
            .receive("ok", this.got_view.bind(this))
            .receive("error", resp => {
                console.log("Unable to join", resp);
            });
    }

    got_view(view) {
        console.log(view);
        this.setState(view.game);
        console.log(this.state);
    }

    render() {
        return <div>
            { debug && <RestartButton channel={this.channel}></RestartButton>}
            { !this.state.opponent && <WaitingRoom channel={this.channel}></WaitingRoom> }
            { this.state.opponent && <Battle channel={this.channel} state={this.state} updateView={(view) => this.got_view(view)}></Battle> }

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
                { true && <Menu channel={this.channel} updateView={this.props.updateView} team={this.player.team} moves={this.player.current_pokemon.moves} ></Menu>}
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
            <div className="pkm-hp">current_hp / {this.pokemon.hp}</div>
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
            <Move move={this.moves[0]} classname="move-1"></Move>
            <Move move={this.moves[1]} classname="move-2"></Move>
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
        this.updateView = props.updateView;

    }

    handleClick(move) {
        console.log(move);
        this.channel.push("move", {move: move}).receive("ok", this.updateView.bind(this));
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
            {this.state.menu == 'moves' && <Moveset updateView={this.props.updateView} channel={this.channel} moves={this.moves}></Moveset>}
            {this.state.menu == 'pokemon'  && <SwitchPkm updateView={this.props.updateView} channel={this.channel} team={this.team}></SwitchPkm>}</div>
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
        this.updateView = props.updateView;
    }

    render() {
        return <div></div>
    }
}