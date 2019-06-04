import ballerina/config;
import celleryio/cellery;

int productCatalogContainerPort = 3550;
string productCatalogContainerHost = "";

int recommendationsContainerPort = 8080;
string recommendationsContainerHost = "";

// Product catalog service component
// This component provides the list of products
// from a JSON file and ability to search products and get individual products.
cellery:Component productCatalogServiceComponent = {
    name: "products",
    source: {
        image: "gcr.io/google-samples/microservices-demo/productcatalogservice:v0.1.1"
    },
    ingresses: {
        tcpIngress: <cellery:TCPIngress>{
            backendPort: productCatalogContainerPort,
            gatewayPort: 31406
        }
    },
    envVars: {
        PORT: {value: productCatalogContainerPort}
    }
};

// Recommendation service component
// Recommends other products based on what's given in the cart.
cellery:Component recommendationServiceComponent = {
    name: "recommendations",
    source: {
        image: "gcr.io/google-samples/microservices-demo/recommendationservice:v0.1.1"
    },
    ingresses: {
        tcpIngress: <cellery:TCPIngress>{
            backendPort: recommendationsContainerPort,
            gatewayPort: 31407
        }
    },
    envVars: {
        PORT: {value: recommendationsContainerPort},
        // PRODUCT_CATALOG_SERVICE_ADDR: {value: "hipstershop_productcatalogservice:3550"},
        PRODUCT_CATALOG_SERVICE_ADDR: {value: ""},
        ENABLE_PROFILER: {value: 0}
    }
};

// Cell Initialization
cellery:CellImage productsCell = {
    components: {
        productCatalogServiceComponent: productCatalogServiceComponent,
        recommendationServiceComponent: recommendationServiceComponent
    }
};

# The Cellery Lifecycle Build method which is invoked for building the Cell Image.
#
# + iName - The Image name
# + return - The created Cell Image
public function build(cellery:ImageName iName) returns error? {
    return cellery:createImage(productsCell, iName);
}

# The Cellery Lifecycle Run method which is invoked for creating a Cell Instance.
#
# + iName - The Image name
# + instances - The map dependency instances of the Cell instance to be created
# + return - The Cell instance
public function run(cellery:ImageName iName, map<cellery:ImageName> instances) returns error? {
    productCatalogContainerHost = cellery:getHost(untaint iName.instanceName, productCatalogServiceComponent);
 
    productsCell.components.recommendationServiceComponent.envVars.PRODUCT_CATALOG_SERVICE_ADDR.value 
    = productCatalogContainerHost + ":" + productCatalogContainerPort;

    return cellery:createInstance(productsCell, iName);
}

