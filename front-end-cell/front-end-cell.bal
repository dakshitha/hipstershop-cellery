import ballerina/config;
import celleryio/cellery;

int productsPort = 31406;
int currencyPort = 31408;
int cartPort = 31407;
int recommendationsPort =31407;
int shippingPort = 31407;
int adsPort = 31406;
int checkoutPort = 5050;

int frontEndPort = 80;

// Front-end service component
// Exposes an HTTP server to serve the website. 
// Does not require signup/login and generates session IDs for all users automatically.

cellery:Component frontEndComponent = {
    name: "front-end",
    source: {
        image: "gcr.io/google-samples/microservices-demo/frontend:v0.1.1"
    },
    ingresses: {
        portal: <cellery:WebIngress>{ // Web ingress will be always exposed globally.
            port: frontEndPort,
            gatewayConfig: {
                vhost: "my-hipstershop.com",
                context: "/"
            }
        }
    },
    envVars: {
        PORT: { value: frontEndPort },
        PRODUCT_CATALOG_SERVICE_ADDR: { value: "" },
        CURRENCY_SERVICE_ADDR: { value: "" },
        CART_SERVICE_ADDR: { value: "" },
        RECOMMENDATION_SERVICE_ADDR: { value: "" },
        SHIPPING_SERVICE_ADDR: { value: "" },
        CHECKOUT_SERVICE_ADDR: { value: "" },
        AD_SERVICE_ADDR: { value: "" }
    },
    dependencies: {
        productsCellDep: <cellery:ImageName>{ org: "wso2", name: "products-cell", ver: "1.0.0"},
        adsCellDep: <cellery:ImageName>{ org: "wso2", name: "ads-cell", ver: "1.0.0"},
        cartCellDep: <cellery:ImageName>{ org: "wso2", name: "cart-cell", ver: "1.0.0"},
        checkoutCellDep: <cellery:ImageName>{ org: "wso2", name: "checkout-cell", ver: "1.0.0"}
    }
};

// Cell Initialization
cellery:CellImage frontEndCell = {
    components: {
        frontEndComponent: frontEndComponent
    }
};

# The Cellery Lifecycle Build method which is invoked for building the Cell Image.
#
# + iName - The Image name
# + return - The created Cell Image
public function build(cellery:ImageName iName) returns error? {
    return cellery:createImage(frontEndCell, iName);
}

# The Cellery Lifecycle Run method which is invoked for creating a Cell Instance.
#
# + iName - The Image name
# + instances - The map dependency instances of the Cell instance to be created
# + return - The Cell instance
public function run(cellery:ImageName iName, map<cellery:ImageName> instances) returns error? {

    //Resolve products URL
    //cellery:Reference productsRef = check cellery:getReference(instances.productsCellDep); -- not supported for TCP
    //Workaround code
    frontEndCell.components.frontEndComponent.envVars.PRODUCT_CATALOG_SERVICE_ADDR.value 
                                  = instances.productsCellDep.instanceName 
                                  + "--gateway-service:" + productsPort;

    //Workaround code
    frontEndCell.components.frontEndComponent.envVars.CURRENCY_SERVICE_ADDR.value 
                                  = instances.checkoutCellDep.instanceName 
                                  + "--gateway-service:" + currencyPort;

    //Resolve cart URL
    //cellery:Reference cartRef = check cellery:getReference(instances.cartCellDep); -- not supported for TCP
    //Workaround cell
   frontEndCell.components.frontEndComponent.envVars.CART_SERVICE_ADDR.value 
                                  = instances.cartCellDep.instanceName 
                                  + "--gateway-service:" + cartPort;
    
    //Workaround code
    frontEndCell.components.frontEndComponent.envVars.RECOMMENDATION_SERVICE_ADDR.value 
                                  = instances.productsCellDep.instanceName 
                                  + "--gateway-service:" + recommendationsPort;

    //Workaround code
    frontEndCell.components.frontEndComponent.envVars.SHIPPING_SERVICE_ADDR.value 
                                  = instances.checkoutCellDep.instanceName 
                                  + "--gateway-service:" + shippingPort;

    //Workaround code
    frontEndCell.components.frontEndComponent.envVars.CHECKOUT_SERVICE_ADDR.value 
                                  = instances.checkoutCellDep.instanceName 
                                  + "--gateway-service:" + checkoutPort;

    //Workaround code
    frontEndCell.components.frontEndComponent.envVars.AD_SERVICE_ADDR.value 
                                  = instances.adsCellDep.instanceName 
                                  + "--gateway-service:" + adsPort;
    
    return cellery:createInstance(frontEndCell, iName);

}

