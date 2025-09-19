import ballerina/io;
import ballerina/log;
import ballerina/grpc;
import car_rental_service;

map<car_rental_service:Car> carDB = {};
map<string[]> userDB = {};
map<string> reservationDB = {};

service "CarRentalService" on new grpc:Listener(50051) {

    remote function add_car(car_rental_service:Car car) returns car_rental_service:Response {
        if carDB.hasKey(car.plate) {
            return { message: "Car with plate " + car.plate + " already exists." };
        }
        carDB[car.plate] = car;
        log:printInfo("Added car: " + car.plate);
        return { message: "Car added successfully." };
    }

    remote function create_users(stream<car_rental_service:User> users) returns car_rental_service:Response {
        error? e = users.forEach(function(car_rental_service:User user) {
            userDB[user.user_id] = [user.name, user.role];
            log:printInfo("Created user: " + user.user_id + " (" + user.role + ")");
        });
        if e is error {
            return { message: "Failed to create users." };
        }
        return { message: "Users created successfully." };
    }

    remote function update_car(car_rental_service:Car car) returns car_rental_service:Response {
        if !carDB.hasKey(car.plate) {
            return { message: "Car with plate " + car.plate + " does not exist." };
        }
        carDB[car.plate] = car;
        log:printInfo("Updated car: " + car.plate);
        return { message: "Car updated successfully." };
    }

    remote function remove_car(car_rental_service:Car car) returns car_rental_service:CarListResponse {
        if carDB.hasKey(car.plate) {
            _ = carDB.remove(car.plate);
            log:printInfo("Removed car: " + car.plate);
        } else {
            log:printWarn("Attempted to remove non-existing car: " + car.plate);
        }
        return { cars: carDB.values().toArray() };
    }

    remote function list_available_cars(car_rental_service:CarSearchRequest request)
            returns stream<car_rental_service:Car, error?> {

        string filter = request.filter.toLowerAscii();

        return new stream<car_rental_service:Car, error?>(
            isolated function() returns record {| car_rental_service:Car value; |}? {
                foreach var [_, car] in carDB.entries() {
                    boolean matchesFilter = filter == "" ||
                        car.make.toLowerAscii().includes(filter) ||
                        car.year.toString().includes(filter);
                    if car.status == "AVAILABLE" && matchesFilter {
                        return { value: car };
                    }
                }
                return ();
            }
        );
    }

    remote function search_car(car_rental_service:Car request) returns car_rental_service:Car|error {
        if carDB.hasKey(request.plate) && carDB[request.plate].status == "AVAILABLE" {
            return carDB[request.plate];
        }
        return error("Car not available or does not exist.");
    }

    remote function add_to_cart(car_rental_service:AddToCartRequest req) returns car_rental_service:Response {
        if !carDB.hasKey(req.car_plate) {
            return { message: "Car with plate " + req.car_plate + " does not exist." };
        }

        if !isValidDateRange(req.start_date, req.end_date) {
            return { message: "Invalid rental dates." };
        }

        string cartEntry = req.car_plate + " (" + req.start_date + " to " + req.end_date + ")";
        if reservationDB.hasKey(req.customer_id) {
            reservationDB[req.customer_id] += ", " + cartEntry;
        } else {
            reservationDB[req.customer_id] = cartEntry;
        }

        log:printInfo("Added to cart: " + cartEntry + " for customer " + req.customer_id);
        return { message: "Car added to cart." };
    }

    remote function place_reservation(car_rental_service:Reservation req) returns car_rental_service:Response {
        if !reservationDB.hasKey(req.customer_id) {
            return { message: "No cars in cart to reserve." };
        }

        foreach var car in req.cars {
            if !carDB.hasKey(car.plate) || carDB[car.plate].status != "AVAILABLE" {
                return { message: "Car " + car.plate + " is not available." };
            }
        }

        int days = calculateDays(req.start_date, req.end_date);
        float totalPrice = 0.0;
        foreach var car in req.cars {
            totalPrice += days * carDB[car.plate].daily_price;
        }

        reservationDB[req.customer_id] = "Reserved: " + totalPrice.toString();

        log:printInfo("Reservation placed for customer " + req.customer_id + ". Total price: $" + totalPrice.toString());
        return { message: "Reservation placed successfully. Total price: $" + totalPrice.toString() };
    }
}

function isValidDateRange(string startDate, string endDate) returns boolean {
    return startDate <= endDate;
}

function calculateDays(string startDate, string endDate) returns int {
    string[] startParts = startDate.split("-");
    string[] endParts = endDate.split("-");

    int startDay = <int>startParts[2];
    int endDay = <int>endParts[2];

    return (endDay - startDay) + 1;
}

