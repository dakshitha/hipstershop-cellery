import ballerina/config;
import celleryio/cellery;

int adsContainerPort = 9555;

// Ad service component
// This component provides text ads based on given context words.

cellery:Component adsServiceComponent = {
    name: "ads",
    source: {
        image: "gcr.io/google-samples/microservices-demo/adservice:v0.1.1"
    },
    ingresses: {
        tcpIngress: <cellery:TCPIngress>{
            backendPort: adsContainerPort,
            gatewayPort: 31406
        }
    },
    envVars: {
        PORT: {
            value: adsContainerPort
        }
    }
};

// Cell Initialization
cellery:CellImage adsCell = {
    components: {
        adsServiceComponent: adsServiceComponent
    }
};

# The Cellery Lifecycle Build method which is invoked for building the Cell Image.
#
# + iName - The Image name
# + return - The created Cell Image
public function build(cellery:ImageName iName) returns error? {
    return cellery:createImage(adsCell, iName);
}

# The Cellery Lifecycle Run method which is invoked for creating a Cell Instance.
#
# + iName - The Image name
# + instances - The map dependency instances of the Cell instance to be created
# + return - The Cell instance
public function run(cellery:ImageName iName, map<cellery:ImageName> instances) returns error? {
    return cellery:createInstance(adsCell, iName);
}