import React from 'react';
import ReactDOM from 'react-dom';
import _ from 'lodash';

export default function game_init(root, channel) {
    ReactDOM.render(<Showdown channel={channel}/>, root);
}

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
    }

    got_view(view) {
        console.log(view);
        this.setState(view);
    }

    render() {
        return <div>
            { false && <WaitingRoom></WaitingRoom> }
            { true && <Battle></Battle> }
            { false && <Result></Result>}
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
        return <div className="waiting-room">Waiting Room.</div>
    }
}

class Battle extends React.Component {
    constructor(props) {
        super(props);
        this.channel = props.channel;
        this.state = {};
    }
    render() {
        return <div className="battle">
                <div className="tab">It's time to D-d-d-d-d-d-duel!</div>
                <img className="artwork" src="https://cdn.discordapp.com/attachments/405465305822003201/546814731944591371/image0.jpg"></img>
                <PkmInfoBar></PkmInfoBar>
                <PkmInfoBar></PkmInfoBar>
                <img className="artwork" src="https://cdn.discordapp.com/attachments/405465305822003201/546814731944591371/image0.jpg"></img>
                <Moveset></Moveset>
            </div>
    }
}

class PkmInfoBar extends React.Component {
    constructor(props) {
        super(props);
        this.state = {};
        
    }
    render() {
        return <div className="info-bar">
            <div className="pkm-name">YOLO</div>
            <div className="pkm-hp">hp = 69/420 ayyyy blaze it lmao</div>
        </div>
    }
}

class Moveset extends React.Component {
    constructor(props) {
        super(props);
        this.state = {};
    }
    render() {
        return <div className="Moveset">
            <Move></Move>
            <Move></Move>
        </div>
    }
}

class Move extends React.Component {
    constructor(props) {
        super(props);
        this.channel = props.channel;
        this.state = {};
    }
    render() {
        return <div>
            <div className="move-name">Blaze it</div>
            <div className="move-type">FIRE</div>
        </div>
    }
    
}
class Result extends React.Component {
    constructor(props) {
        super(props);
        this.channel = props.channel;
        this.state = {};
    }
    // result + button to redirect to / ?
    render() {
        return <div className="redirect">
            
        </div>
    }
}

class Team extends React.Component {
    constructor(props) {
        super(props);
        this.channel = props.channel;
        this.state = {};
    }

}