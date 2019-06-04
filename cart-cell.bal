import ballerina/config;
import celleryio/cellery;

int cacheContainerPort = 6379;
string cacheContainerHost = "";

int cartContainerPort = 7070;
string cartContainerHost = "";


// Cache component
// Redis-based cache
cellery:Component cacheServiceComponent = {
    name: "cache",
    source: {
        image: "redis:alpine"
    },
    ingresses: {
        tcpIngress: <cellery:TCPIngress>{
            backendPort: cacheContainerPort,
            gatewayPort: cacheContainerPort //used the cacheContainerPort as the backendPort 
        }
    }
};

// Cart service component
// Stores the items in the user's shipping cart in Redis and retrieves it.
cellery:Component cartServiceComponent = {
    name: "cart",
    source: {
        image: "gcr.io/google-samples/microservices-demo/cartservice:v0.1.1"
    },
    ingresses: {
        tcpIngress: <cellery:TCPIngress>{
            backendPort: cartContainerPort,
            gatewayPort: 31407
        }
    },
    envVars: {
        PORT: {value: cartContainerPort},
        // REDIS_ADDR: {value: "hipstershop_redis:6379"},
        REDIS_ADDR: {value: ""},
        LISTEN_ADDR: {value: "0.0.0.0"},
        CART_SERVICE_ADDR: {value: ""}
    }
};

// Cell Initialization
cellery:CellImage cartCell = {
    components: {
        cacheServiceComponent: cacheServiceComponent,
        cartServiceComponent: cartServiceComponent
    }
};

# The Cellery Lifecycle Build method which is invoked for building the Cell Image.
#
# + iName - The Image name
# + return - The created Cell Image
public function build(cellery:ImageName iName) returns error? {
    return cellery:createImage(cartCell, iName);
}

# The Cellery Lifecycle Run method which is invoked for creating a Cell Instance.
#
# + iName - The Image name
# + instances - The map dependency instances of the Cell instance to be created
# + return - The Cell instance
public function run(cellery:ImageName iName, map<cellery:ImageName> instances) returns error? {
    cacheContainerHost = cellery:getHost(untaint iName.instanceName, cacheServiceComponent);
    
    cartCell.components.cartServiceComponent.envVars.REDIS_ADDR.value 
    = cacheContainerHost + ":" + cacheContainerPort;

    return cellery:createInstance(cartCell, iName);
}

