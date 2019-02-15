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
    }

    render() {
        let users = _.map(this.state.users, function(user, ii) {
           return <div key={ii}>
               {user.name}

               <Team team={user.team}/>
           </div>
        });

        return <div>
            <div>
                {users}
            </div>
        </div>
    }
}

function Team(props) {
    let team = props.team;

    return _.map(team, function(pokemon, ii) {
        return <div key={ii}>
            {pokemon.name}<br />
            {pokemon.hp}
        </div>;
    });
}