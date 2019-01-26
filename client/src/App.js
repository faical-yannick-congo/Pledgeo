import React, { Component } from "react";
import PledgeoContract from "./contracts/Pledgeo.json";
import getWeb3 from "./utils/getWeb3";

import "./App.css";

import Button from 'react-bootstrap/lib/Button';
import Form from 'react-bootstrap/lib/Form';
import FormGroup from 'react-bootstrap/lib/FormGroup';
import FormControl from 'react-bootstrap/lib/FormControl';
// import HelpBlock from 'react-bootstrap/lib/HelpBlock';
import Grid from 'react-bootstrap/lib/Grid';
import Row from 'react-bootstrap/lib/Row';
import Panel from 'react-bootstrap/lib/Panel';

import BootstrapTable from 'react-bootstrap-table/lib/BootstrapTable';
import TableHeaderColumn from 'react-bootstrap-table/lib/TableHeaderColumn';

import 'react-bootstrap-table/dist/react-bootstrap-table-all.min.css';


const etherscanBaseUrl = "https://rinkeby.etherscan.io";

class App extends Component {
  constructor(props) {
    super(props)
    this.state = {
      pledgeoInstance: undefined,
      managerAddress: undefined,
      platformManagers: [],
      communityDescription: undefined,
      communities: [],
      etherscanLink: "https://rinkeby.etherscan.io",
      contractOwner: null,
      account: null,
      web3: null
    }
    this.handleAddPlatformManager = this.handleAddPlatformManager.bind(this)
    this.handleChangeAddPlatformManager = this.handleChangeAddPlatformManager.bind(this)
    this.handleAddCommunity = this.handleAddCommunity.bind(this)
    this.handleChangeAddCommunity = this.handleChangeAddCommunity.bind(this)
  }

  componentDidMount = async () => {
    try {
      // Get network provider and web3 instance.
      const web3 = await getWeb3();

      // Use web3 to get the user's accounts.
      const accounts = await web3.eth.getAccounts();

      // Get the contract instance.
      const networkId = await web3.eth.net.getId();
      const deployedNetwork = PledgeoContract.networks[networkId];
      const instance = new web3.eth.Contract(
        PledgeoContract.abi,
        deployedNetwork && deployedNetwork.address,
      );

      // Set web3, accounts, and contract to the state, and then proceed with an
      // example of interacting with the contract's methods.
      this.setState({ pledgeoInstance: instance, web3: web3, contractOwner: accounts[0], account: accounts[1]});
      this.addEventListener(this)
    }
    catch (error) {
      // Catch any errors for any of the above operations.
      alert(
        `Failed to load web3, accounts, or contract. Check console for details.`,
      );
      console.error(error);
    }
  };

  // Handle form data change
  handleChangeAddPlatformManager(event) {
      switch(event.target.name) {
        case "managerAddress":
              this.setState({"managerAddress": event.target.value})
              break;
      }
  }

    // Handle form data change
    handleChangeAddCommunity(event) {
      switch(event.target.name) {
        case "communityDescription":
              this.setState({"communityDescription": event.target.value})
              break;
      }
  }

  // Handle form submit
  async handleAddPlatformManager(event) {
    if (typeof this.state.pledgeoInstance !== 'undefined') {
      event.preventDefault();
      let result = await this.state.pledgeoInstance.methods.addPlatformManager(this.state.managerAddress).send({from: this.state.contractOwner})
      this.setLastTransactionDetails(result)
    }
  }

  // Handle form submit
  async handleAddCommunity(event) {
    if (typeof this.state.pledgeoInstance !== 'undefined') {
      event.preventDefault();
      let result = await this.state.pledgeoInstance.methods.addCommunity(this.state.communityDescription).send({from: this.state.account})
      this.setLastTransactionDetails(result)
    }
  }

  setLastTransactionDetails(result) {
    if(result.tx !== 'undefined') {
      this.setState({etherscanLink: etherscanBaseUrl+"/tx/"+result.tx})
    }
    else {
      this.setState({etherscanLink: etherscanBaseUrl})
    }
  }

  addEventListener(component) {
    this.state.pledgeoInstance.events.AddPlatformManager({fromBlock: 0, toBlock: 'latest'})
    .on('data', function(event){
      console.log(event); // same results as the optional callback above
      var newPlatformManagersArray = component.state.platformManagers.slice()
      newPlatformManagersArray.push(event.returnValues)
      component.setState({ platformManagers: newPlatformManagersArray })
    })
    .on('error', console.error);

    this.state.pledgeoInstance.events.AddCommunity({fromBlock: 0, toBlock: 'latest'})
    .on('data', function(event){
      console.log(event); // same results as the optional callback above
      var newCommunitiesArray = component.state.communities.slice()
      newCommunitiesArray.push(event.returnValues)
      component.setState({ communities: newCommunitiesArray })
    })
    .on('error', console.error);
  }

  render() {
    if (!this.state.web3) {
      return <div>Loading Web3, accounts, and contract...</div>;
    }
    return (
      <div className="App">
        <Grid>
          <Row>
            <a href={this.state.etherscanLink} target="_blank">Last Transaction Details</a>
          </Row>
          <Row>
            <Panel>
              <Panel.Heading>Pledgeo</Panel.Heading>
              <Form onSubmit={this.handleAddPlatformManager}>
                <FormGroup
                  controlId="fromCreatePlatformManager"
                >
                  <FormControl
                    componentClass="textarea"
                    name="managerAddress"
                    value={this.state.managerAddress}
                    placeholder="Enter manager address"
                    onChange={this.handleChangeAddPlatformManager}
                  />
                  <Button type="submit">Add Platform Manager</Button>
                </FormGroup>
              </Form>
              <Form onSubmit={this.handleAddCommunity}>
                <FormGroup
                  controlId="fromCreateCommunity"
                >
                  <FormControl
                    componentClass="textarea"
                    name="communityDescription"
                    value={this.state.communityDescription}
                    placeholder="Enter description"
                    onChange={this.handleChangeAddCommunity}
                  />
                  <Button type="submit">Add Community</Button>
                </FormGroup>
              </Form>
            </Panel>
          </Row>
        </Grid>
        <Row>
          <Panel>
            <Panel.Heading>"AddPlatformManager" Events</Panel.Heading>
            <BootstrapTable data={this.state.platformManagers} striped hover>
              <TableHeaderColumn isKey dataField='manager'>Platform manager address</TableHeaderColumn>
            </BootstrapTable>
          </Panel>
        </Row>
        <Row>
          <Panel>
            <Panel.Heading>"AddCommunity" Events</Panel.Heading>
            <BootstrapTable data={this.state.communities} striped hover>
              <TableHeaderColumn isKey dataField='community_id'>Community ID</TableHeaderColumn>
              <TableHeaderColumn dataField='manager'>Platform manager address</TableHeaderColumn>
            </BootstrapTable>
          </Panel>
        </Row>
      </div>
    );
  }

}

export default App;
