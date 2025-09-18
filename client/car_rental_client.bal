import ballerina/grpc;
import ballerina/io;
import ballerina/log;

client service CarRentalServiceClient {
    endpoint grpc:Caller grpcCaller;

    function init() returns error? {
        self.grpcCaller = check new grpc:Caller("localhost:50051");
    }

    remote function list_available_cars(string filter) returns stream<Car> {
        CarSearchRequest req = {filter: filter};
        return self.grpcCaller->list_available_cars(req);
    }

    remote function add_to_cart(string customerId, string plate, string startDate, string endDate) returns Response {
        AddToCartRequest req = {customer_id: customerId, car_plate: plate, start_date: startDate, end_date: endDate};
        return check self.grpcCaller->add_to_cart(req);
    }

    remote function place_reservation(Reservation reservation) returns Response {
        return check self.grpcCaller->place_reservation(reservation);
    }
}

public function main() returns error? {
    CarRentalServiceClient client = check new;

    // Example: List available cars
    stream<Car> cars = check client.list_available_cars("Toyota");
    checkpanic cars.forEach(function(Car c) {
        io:println("Car: " + c.make + " " + c.model);
    });

    // Example: Add car to cart
    Response addResponse = check client.add_to_cart("customer1", "ABC123", "2025-09-20", "2025-09-25");
    io:println(addResponse.message);
}
