require_relative 'test_helper'

TEST_DATA_DIRECTORY = 'test/test_data'

describe "TripDispatcher class" do
  def build_test_dispatcher
    return RideShare::TripDispatcher.new(
    directory: TEST_DATA_DIRECTORY
    )
  end
  
  describe "Initializer" do
    it "is an instance of TripDispatcher" do
      dispatcher = build_test_dispatcher
      expect(dispatcher).must_be_kind_of RideShare::TripDispatcher
    end
    
    it "establishes the base data structures when instantiated" do
      dispatcher = build_test_dispatcher
      [:trips, :passengers].each do |prop|
        expect(dispatcher).must_respond_to prop
      end
      
      expect(dispatcher.trips).must_be_kind_of Array
      expect(dispatcher.passengers).must_be_kind_of Array
      # expect(dispatcher.drivers).must_be_kind_of Array
    end
    
    it "loads the development data by default" do
      # Count lines in the file, subtract 1 for headers
      trip_count = %x{wc -l 'support/trips.csv'}.split(' ').first.to_i - 1
      dispatcher = RideShare::TripDispatcher.new
      expect(dispatcher.trips.length).must_equal trip_count
    end
  end
  
  describe "passengers" do
    describe "find_passenger method" do
      before do
        @dispatcher = build_test_dispatcher
      end
      
      it "throws an ArgumentError for a bad ID" do
        expect{ @dispatcher.find_passenger(0) }.must_raise ArgumentError
      end
      
      it "finds a passenger instance" do
        passenger = @dispatcher.find_passenger(2)
        expect(passenger).must_be_kind_of RideShare::Passenger
      end
    end
    
    describe "Passenger & Trip loader methods" do
      before do
        @dispatcher = build_test_dispatcher
      end
      
      it "accurately loads passenger information into passengers array" do
        first_passenger = @dispatcher.passengers.first
        last_passenger = @dispatcher.passengers.last
        
        expect(first_passenger.name).must_equal "Passenger 1"
        expect(first_passenger.id).must_equal 1
        expect(last_passenger.name).must_equal "Passenger 8"
        expect(last_passenger.id).must_equal 8
      end
      
      it "connects trips and passengers" do
        dispatcher = build_test_dispatcher
        dispatcher.trips.each do |trip|
          expect(trip.passenger).wont_be_nil
          expect(trip.passenger.id).must_equal trip.passenger_id
          expect(trip.passenger.trips).must_include trip
        end
      end
    end
  end
  
  describe "drivers" do
    describe "find_driver method" do
      before do
        @dispatcher = build_test_dispatcher
      end
      
      it "throws an ArgumentError for a bad ID" do
        expect { @dispatcher.find_driver(0) }.must_raise ArgumentError
      end
      
      it "finds a driver instance" do
        driver = @dispatcher.find_driver(2)
        expect(driver).must_be_kind_of RideShare::Driver
      end
      
      it "checks the accuracy by comapring the driver_id of the found driver" do 
        driver_to_find = 2
        driver = @dispatcher.find_driver(driver_to_find)
        expect(driver.id).must_equal driver_to_find
      end
      
    end
    
    describe "Driver & Trip loader methods" do
      before do
        @dispatcher = build_test_dispatcher
      end
      
      it "accurately loads driver information into drivers array" do
        first_driver = @dispatcher.drivers.first
        last_driver = @dispatcher.drivers.last
        
        expect(first_driver.name).must_equal "Driver 1 (unavailable)"
        expect(first_driver.id).must_equal 1
        expect(first_driver.status).must_equal :UNAVAILABLE
        expect(last_driver.name).must_equal "Driver 3 (no trips)"
        expect(last_driver.id).must_equal 3
        expect(last_driver.status).must_equal :AVAILABLE
      end
      
      it "connects trips and drivers" do
        dispatcher = build_test_dispatcher
        
        dispatcher.trips.each do |trip|
          expect(trip.driver).wont_be_nil
          expect(trip.driver.id).must_equal trip.driver_id
          expect(trip.driver.trips).must_include trip
        end
      end
    end
  end
  
  describe "ongoing trip" do
    before do
      @passenger_master_id = 2
      @dispatcher = RideShare::TripDispatcher.new
      @trip = @dispatcher.request_trip(@passenger_master_id)
    end
    
    it "verifies that a newly request trip creates a new instance of trip" do
      expect(@trip).must_be_kind_of RideShare::Trip
    end
    
    it "verifies that the trip was added for the appropriate passenger, that the passed-in ID match the ID of the Trip instance" do
      passenger = @dispatcher.find_passenger(@passenger_master_id)
      expect(passenger.trips).must_include @trip
    end
    
    it "verifies that the trip's ongoing nature is reflected in key measurements: end time, cost, rating should all be nil" do 
      expect(@trip.end_time).must_be_nil
      expect(@trip.cost).must_be_nil
      expect(@trip.rating).must_be_nil
    end
    
    it "verifies that the trip starts at Time.now" do
      time_now = Time.now.to_i
      expect(@trip.start_time.to_i).must_be_close_to time_now
    end 
    
    # it "raises an ArgumentError if there are no available drivers" do
    #   ridiculus_number_of_trips = 500 # to use up all available drivers 
    #   expect{
    #     ridiculus_number_of_trips.times do |i|
    #       @dispatcher.request_trip( i + 1 )
    #     end
    #   }.must_raise ArgumentError
    # end
    
  end
  
  describe "request_trip snapshot comparison" do
    before do
      @passenger_master_id = 2
      @dispatcher = RideShare::TripDispatcher.new
      @passenger = @dispatcher.passengers.find { |passenger| passenger.id == @passenger_master_id }
      @driver = @dispatcher.drivers.find {|driver| driver.status == :AVAILABLE }
      
    end
    
    it "verifies the driver assignment" do
      # uses conditions to measure change once request_trip has run   
      new_driver_id = @dispatcher.request_trip(@passenger_master_id).driver_id
      
      expect(@driver.id).must_equal new_driver_id
    end 
    
    it "verifies that driver assignments are first prioritized for new drivers then by the driver that last had a ride a long time ago" do
      dummy = @dispatcher.drivers.dup
      dummy.reject! { |driver| driver.status == :UNAVAILABLE}
      verification = nil
      dummy.each do |driver| 
        verification = true if driver.trips == []
      end
      if verification == true
        expect(@driver.trips).must_equal []
      else
        dummy.sort_by! {|driver| driver.end_time}
        calculated_driver = dummy[0].id
        chosen_driver = dispatcher.request_trip(passenger_master_id).driver_id
        expect(chosen_driver).must_equal calculated_driver
      end
    end
    
    it "verifies that the driver assigned WAS available and IS NOW unavailable" do
      # uses conditions to measure change once request_trip has run
      expect(@driver.status).must_equal :AVAILABLE  
      new_driver_id = @dispatcher.request_trip(@passenger_master_id).driver_id
      
      new_driver = @dispatcher.find_driver(new_driver_id)
      expect(new_driver.status).must_equal :UNAVAILABLE
    end 
    
    it "veifies that the array of a passenger's trips has increased to reflect the new trip" do
      # uses conditions to measure change once request_trip has run
      dummy = @passenger.trips.dup # duplication is to prevent the instance-variable update to affect comparison
      trips_before_new_trip = dummy 
      @dispatcher.request_trip(@passenger_master_id)
      trips_after_new_trip = @passenger.trips
      new_trip_count = trips_before_new_trip.length + 1
      expect(trips_after_new_trip.length).must_equal new_trip_count
    end
    
    it "veifies that the array of a driver's trips has increased to reflect the new trip" do
      # uses conditions to measure change once request_trip has run
      dummy = @driver.trips.dup # duplication is to prevent the instance-variable update to affect comparison
      trips_before_new_trip = dummy
      @dispatcher.request_trip(@passenger_master_id)
      trips_after_new_trip = @driver.trips
      new_trip_count = trips_before_new_trip.length + 1
      expect(trips_after_new_trip.length).must_equal new_trip_count
    end
    
    it "verifies that the total number of trips has increased in trip_dispatcher" do
      dummy = @dispatcher.trips.dup
      trips_before_new_trip = dummy
      new_trip_count = trips_before_new_trip.length + 1
      @dispatcher.request_trip(@passenger_master_id)
      trips_after_new_trip = @dispatcher.trips
      expect(trips_after_new_trip.length).must_equal new_trip_count
    end
    
    it "raises an ArgumentError if there are no available drivers" do
      ridiculus_number_of_trips = 500 # to use up all available drivers 
      expect{
      ridiculus_number_of_trips.times do |i|
        @dispatcher.request_trip( i + 1 )
      end
    }.must_raise ArgumentError
    
  end
end
end
