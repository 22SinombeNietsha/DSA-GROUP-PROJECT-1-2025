import ballerina/io;
import car_rental_service as carRental;

public function main() returns error? {

    // Connect to the gRPC server
    carRental:CarRentalServiceClient client = check new ("http://localhost:50051");

    // === Admin: Add a car ===
    carRental:Car car = {
        plate: "DEF456",
        make: "Ford",
        model: "Focus",
        year: 2019,
        daily_price: 45.0,
        mileage: 12000,
        status: "AVAILABLE"
    };

    carRental:Response addCarResp = check client->add_car(car);
    io:println("Add Car: ", addCarResp.message);

    // === Admin: Create users using streaming ===
    stream<carRental:User, error?> userStream = new({
        next: function () returns record {| carRental:User value; |}? {
            // For demo, only sending one user
            return {
                value: {
                    user_id: "U001",
                    name: "Alice",
                    role: "customer"
                }
            };
        }
    });

    carRental:Response userResp = check client->create_users(userStream);
    io:println("Create Users: ", userResp.message);

    // === Admin: Update the car's price ===
    car.daily_price = 49.99;
    carRental:Response updateResp = check client->update_car(car);
    io:println("Update Car: ", updateResp.message);

    // === Admin: Remove car from system ===
    carRental:CarListResponse removedCars = check client->remove_car(car);
    io:println("After removal, cars in system:");
    foreach var c in removedCars.cars {
        io:println("- ", c.plate);
    }

    // === Customer: List available cars ===
    carRental:CarSearchRequest searchFilter = {
        filter: "Toyota"
    };
    stream<carRental:Car, error?> availableCars = check client->list_available_cars(searchFilter);
    io:println("Available Cars:");
    check from carRental:Car carItem in availableCars
        do {
            io:println("- ", carItem.make, " ", carItem.model);
        };

    // === Customer: Search for a car by plate ===
    carRental:Car searchCar = {
        plate: "ABC123",
        make: "",
        model: "",
        year: 0,
        daily_price: 0.0,
        mileage: 0,
        status: ""
    };

    carRental:Car found = check client->search_car(searchCar);
    io:println("Search Result: ", found.make, " ", found.model);

    // === Customer: Add to cart ===
    carRental:AddToCartRequest cartRequest = {
        customer_id: "U001",
        car_plate: "ABC123",
        start_date: "2025-09-20",
        end_date: "2025-09-23"
    };

    carRental:Response cartResp = check client->add_to_cart(cartRequest);
    io:println("Add to Cart: ", cartResp.message);

    // === Customer: Place reservation ===
    carRental:Reservation reservation = {
        customer_id: "U001",
        cars: [car],
        start_date: "2025-09-20",
        end_date: "2025-09-23",
        total_price: 135.0
    };

    carRental:Response resResp = check client->place_reservation(reservation);
    io:println("Place Reservation: ", resResp.message);
}


    


