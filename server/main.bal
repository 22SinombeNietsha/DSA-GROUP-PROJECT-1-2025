import ballerina/grpc;
import ballerina/log;

// Import generated types from your proto module
import car_rental_service as carRental;

service class CarRentalService on grpc:Service {
    
    remote function add_car(carRental:Car car) returns carRental:Response {
        log:printInfo("Admin adding car: " + car.plate);
        // Add car to inventory (implement your storage logic here)
        return { message: "Car added successfully" };
    }

    remote function create_users(stream<carRental:User> users) returns carRental:Response {
        // Handle multiple user creation logic (stream consumption)
        // For demo, just return success immediately
        return { message: "Users created successfully" };
    }

    remote function update_car(carRental:Car car) returns carRental:Response {
        log:printInfo("Admin updating car: " + car.plate);
        // Implement your update logic here
        return { message: "Car updated successfully" };
    }

    remote function remove_car(carRental:Car car) returns carRental:CarListResponse {
        log:printInfo("Admin removing car: " + car.plate);
        // Implement your remove logic here and return updated list
        // Here, returning a dummy list for demonstration
        return { cars: [car] };
    }

    remote function list_available_cars(carRental:CarSearchRequest request) returns stream<carRental:Car, error?> {
        // Return filtered cars based on request.filter (simple example here)
        stream<carRental:Car, error?> cars = from var car in getAvailableCars()
                                             where car.make.toLowerAscii().contains(request.filter.toLowerAscii())
                                             select car;
        return cars;
    }

    remote function search_car(carRental:Car request) returns carRental:Car {
        // Implement search logic by plate, for demo just return input car
        return request;
    }

    remote function add_to_cart(carRental:AddToCartRequest req) returns carRental:Response {
        log:printInfo("Car added to cart: " + req.car_plate);
        // Add the car to customer's cart logic
        return { message: "Car added to cart successfully" };
    }

    remote function place_reservation(carRental:Reservation reservation) returns carRental:Response {
        log:printInfo("Reservation placed for: " + reservation.customer_id);
        // Verify availability, calculate price, and confirm booking here
        return { message: "Reservation confirmed" };
    }

    // Helper function to get dummy available cars
    function getAvailableCars() returns carRental:Car[] {
        return [
            { plate: "ABC123", make: "Toyota", model: "Camry", year: 2020, daily_price: 50, mileage: 10000, status: "AVAILABLE" },
            { plate: "XYZ456", make: "Honda", model: "Civic", year: 2022, daily_price: 60, mileage: 5000, status: "AVAILABLE" }
        ];
    }
}

// Initialize gRPC listener on port 50051
listener grpc:Listener carRentalListener = new(50051);

// Bind service to listener
service CarRentalService serviceObj bind carRentalListener;

public function main() returns error? {
    log:printInfo("Starting Car Rental gRPC server...");
    check carRentalListener.start();
}
