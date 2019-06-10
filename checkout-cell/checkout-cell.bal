import ballerina/config;
import ballerina/io;
import celleryio/cellery;

int emailContainerPort = 8080;
string emailContainerHost = "";

int paymentContainerPort = 50051;
string paymentContainerHost = "";

int shippingContainerPort = 50051;
string shippingContainerHost = "";

int currencyContainerPort = 7000;
string currencyContainerHost = "";

int checkoutContainerPort = 5050;
string checkoutContainerHost = "";

int productsGatewayPort = 31406;
int cartGatewayPort =31407;


// Email service component
// Sends users an order confirmation email (mock).
cellery:Component emailServiceComponent = {
    name: "email",
    source: {
        image: "gcr.io/google-samples/microservices-demo/emailservice:v0.1.1"
    },
    ingresses: {
        tcpIngress: <cellery:TCPIngress>{
            backendPort: emailContainerPort,
            gatewayPort: 31405
        }
    },
    envVars: {
        PORT: {value: emailContainerPort},
        ENABLE_PROFILER: {value: 0}   
    }
};

// Payment service component
// Charges the given credit card info (mock) with the given amount and returns a transaction ID.
cellery:Component paymentServiceComponent = {
    name: "payment",
    source: {
        image: "gcr.io/google-samples/microservices-demo/paymentservice:v0.1.1"
    },
    ingresses: {
        tcpIngress: <cellery:TCPIngress>{
            backendPort: paymentContainerPort,
            gatewayPort: 31406
        }
    },
    envVars: {
        PORT: {value: paymentContainerPort}
    }
};

// Shipping service component
// Gives shipping cost estimates based on the shopping cart. Ships items to the given address (mock)
cellery:Component shippingServiceComponent = {
    name: "shipping",
    source: {
        image: "gcr.io/google-samples/microservices-demo/shippingservice:v0.1.1"
    },
    ingresses: {
        tcpIngress: <cellery:TCPIngress>{
            backendPort: shippingContainerPort,
            gatewayPort: 31407
        }
    },
    envVars: {
        PORT: {value: shippingContainerPort}
    }
};

// Currency service component
// Converts one money amount to another currency. 
// Uses real values fetched from European Central Bank. It's the highest QPS service.
cellery:Component currencyServiceComponent = {
    name: "currency",
    source: {
        image: "gcr.io/google-samples/microservices-demo/currencyservice:v0.1.1"
    },
    ingresses: {
        tcpIngress: <cellery:TCPIngress>{
            backendPort: currencyContainerPort,
            gatewayPort: 31408
        }
    },
    envVars: {
        PORT: {value: currencyContainerPort}
    }
};

// Checkout service component
// Retrieves user cart, prepares order and orchestrates the payment, 
// shipping and the email notification.

cellery:Component checkoutServiceComponent = {
    name: "checkout",
    source: {
        image: "gcr.io/google-samples/microservices-demo/checkoutservice:v0.1.1"
    },
    ingresses: {
        tcpIngress: <cellery:TCPIngress>{
            backendPort: checkoutContainerPort,
            gatewayPort: 31409
        }
    },
    envVars: {
        PORT: {value: checkoutContainerPort},
        //same-cell components
        EMAIL_SERVICE_ADDR: {value: ""},
        PAYMENT_SERVICE_ADDR: {value: ""},
        SHIPPING_SERVICE_ADDR: {value: ""},
        CURRENCY_SERVICE_ADDR: {value: ""},

        //components of external cells
        PRODUCT_CATALOG_SERVICE_ADDR: {value: ""},
        CART_SERVICE_ADDR: {value: ""}  
    },
    dependencies: {
         productsCellDep: <cellery:ImageName>{ org: "wso2", name: "products-cell", ver: "1.0.0"},
         cartCellDep: <cellery:ImageName>{ org: "wso2", name: "cart-cell", ver: "1.0.0" } 
    }
};

// Cell Initialization
cellery:CellImage checkoutCell = {
    components: {
        emailServiceComponent: emailServiceComponent,
        paymentServiceComponent: paymentServiceComponent,
        shippingServiceComponent: shippingServiceComponent,
        currencyServiceComponent: currencyServiceComponent,
        checkoutServiceComponent: checkoutServiceComponent
    }
};

# The Cellery Lifecycle Build method which is invoked for building the Cell Image.
#
# + iName - The Image name
# + return - The created Cell Image
public function build(cellery:ImageName iName) returns error? {
    return cellery:createImage(checkoutCell, iName);
}

# The Cellery Lifecycle Run method which is invoked for creating a Cell Instance.
#
# + iName - The Image name
# + instances - The map dependency instances of the Cell instance to be created
# + return - The Cell instance
public function run(cellery:ImageName iName, map<cellery:ImageName> instances) returns error? {

    emailContainerHost = cellery:getHost(untaint iName.instanceName, emailServiceComponent);
    checkoutCell.components.checkoutServiceComponent.envVars.EMAIL_SERVICE_ADDR.value
                                                 = emailContainerHost + ":" + emailContainerPort;

    paymentContainerHost = cellery:getHost(untaint iName.instanceName, paymentServiceComponent);
    checkoutCell.components.checkoutServiceComponent.envVars.PAYMENT_SERVICE_ADDR.value
                                                 = paymentContainerHost + ":" + paymentContainerPort;

    shippingContainerHost = cellery:getHost(untaint iName.instanceName, shippingServiceComponent);
    checkoutCell.components.checkoutServiceComponent.envVars.SHIPPING_SERVICE_ADDR.value
                                                 = shippingContainerHost + ":" + shippingContainerPort;

    currencyContainerHost = cellery:getHost(untaint iName.instanceName, currencyServiceComponent);
    io:println(currencyContainerHost);
    checkoutCell.components.checkoutServiceComponent.envVars.CURRENCY_SERVICE_ADDR.value
                                                 = currencyContainerHost + ":" + currencyContainerPort;

    //Resolve products URL
    //cellery:Reference productsRef = check cellery:getReference(instances.productsCellDep); -- not supported for TCP
    //Workaround code
    checkoutCell.components.checkoutServiceComponent.envVars.PRODUCT_CATALOG_SERVICE_ADDR.value 
                                = instances.productsCellDep.instanceName 
                                + "--gateway-service:" + productsGatewayPort;

    //Resolve cart URL
    //cellery:Reference cartRef = check cellery:getReference(instances.cartCellDep); -- not supported for TCP
    //Workaround cell
   checkoutCell.components.checkoutServiceComponent.envVars.CART_SERVICE_ADDR.value 
                                  = instances.cartCellDep.instanceName 
                                  + "--gateway-service:" + cartGatewayPort;
    
    return cellery:createInstance(checkoutCell, iName);

}

