remix wip 
flare network validator registry --> map owner/sender to a max of 5 nodeIDs to be used in flare ecosystem dapps

example deployed coston call:

```
const Web3 = require('web3');
const web3 = new Web3('https://coston-api.flare.network/ext/C/rpc'); 

const contractAddress = '0x24f0A2342550050C17E3d47E825Da8a3Eb3E60A1'; 
const contractABI = [
    {
        constant: true,
        inputs: [],
        name: 'getAllOwnersAndNodes',
        outputs: [
            {
                name: 'owners',
                type: 'address[]'
            },
            {
                name: 'nodes',
                type: 'string[]'
            }
        ],
        payable: false,
        stateMutability: 'view',
        type: 'function'
    }
];

const contract = new web3.eth.Contract(contractABI, contractAddress);

async function getAllOwnersAndNodes() {
    try {
        const result = await contract.methods.getAllOwnersAndNodes().call();
        const owners = result[0];
        const nodes = result[1];

        console.log('Owners:', owners);
        console.log('Nodes:', nodes);
    } catch (error) {
        console.error('Error:', error);
    }
}

getAllOwnersAndNodes();
```