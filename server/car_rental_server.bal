import ballerina/grpc;
import ballerina/log;

service class CarRentalService on grpc:Listener {

    remote function add_car(Car car) returns Response {
        log:printInfo("Admin adding car: " + car.plate);
        // Add car to inventory (you can store this in memory or database)
        return {message: "Car added successfully"};
    }

    remote function create_users(stream<User> users) returns Response {
        // Handle multiple users creation logic
        return {message: "Users created successfully"};
    }

    remote function update_car(Car car) returns Response {
        log:printInfo("Admin updating car: " + car.plate);
        return {message: "Car updated successfully"};
    }

    remote function remove_car(Car car) returns CarListResponse {
        log:printInfo("Admin removing car: " + car.plate);
        return CarListResponse{cars: [car]};  // Return updated list (remove car logic)
    }

    remote function list_available_cars(CarSearchRequest searchRequest) returns stream<Car> {
        stream<Car> availableCars = from car in getAvailableCars()
                                     select car;
        return availableCars;
    }

    remote function search_car(Car car) returns Car {
        return car;  // Return car details if found
    }

    remote function add_to_cart(AddToCartRequest cartRequest) returns Response {
        log:printInfo("Car added to cart: " + cartRequest.car_plate);
        return {message: "Car added to cart successfully"};
    }

    remote function place_reservation(Reservation reservation) returns Response {
        log:printInfo("Reservation placed for: " + reservation.customer_id);
        return {message: "Reservation confirmed"};
    }

    function getAvailableCars() returns Car[] {
        return [
            {plate: "ABC123", make: "Toyota", model: "Camry", year: 2020, daily_price: 50, mileage: 10000, status: "AVAILABLE"},
            {plate: "XYZ456", make: "Honda", model: "Civic", year: 2022, daily_price: 60, mileage: 5000, status: "AVAILABLE"}
        ];
    }
}

service object carRentalServer on grpc:Listener {
    host: "localhost", 
    port: 50051
};

public function startServer() returns error? {
    check carRentalServer->start();
}
 ballerina.project.run