const fs = require('fs');

const data = {
  address: "0xC522E6A633545872f1afc0cdD7b2D96d97E3dE67",
  name: "Ftso_xyz",
  url: "Example.com",
  logo: "12345678.png",
  nodeID: ["node1", "node2", "node3", "node4", "node5"],
};

//example, may not be real
//const solidifi = ["name", "address", "nodeID", "url", "logo_uri"];

//example, may not be real
const Mapping = JSON.parse(fs.readFileSync("./examples/flaremetrics.json"));
const matchingKeys = Object.keys(Mapping);


//dapp defined
//const custom = ["custom_address", "outoforder_name", "whateverurl", "samplepicture", "nodes"];

let formatType = "flareMetrics";


function transformData(data, formatType) {
  let formatArray;

  if (formatType === "flareMetrics") {
    formatArray = matchingKeys;
  } else {
    formatArray = [];
  }

  let transformedData = {};

  formatArray.forEach((key) => {
    const mappedKey = Mapping[key] || key;

    // Dynamically find keys in the data object
    const matchingKeys = Object.keys(data).filter(
      (dataKey) => dataKey.toLowerCase() === mappedKey.toLowerCase()
    );

    if (matchingKeys.length > 0) {
      transformedData[key] = customMappingFunction(mappedKey, data[matchingKeys[0]]);
    }
  });

  return transformedData;
}

function customMappingFunction(key, input) {
  let transformedData = [];

  if (input !== undefined) {
    if (Array.isArray(input)) {
      input.forEach((node) => {
        transformedData.push(node);
      });
    } else {
      transformedData.push(input);
    }
  }

  return transformedData;
}

const transformedData = transformData(data, formatType);
console.log(transformedData);

//example real call
/*
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
*/
