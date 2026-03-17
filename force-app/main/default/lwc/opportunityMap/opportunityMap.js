import { LightningElement, track } from 'lwc';
import getOpportunitiesWithinRadius from '@salesforce/apex/OpportunityMapController.getOpportunitiesWithinRadius';

export default class OpportunityMap extends LightningElement {
    @track searchAddress = '';
    @track mapMarkers = [];
    @track center = { latitude: 0, longitude: 0 };
    @track zoomLevel = 10;
    @track selectedOpportunity = null;
    @track opportunities = [];
    radius = 7; // km

    handleAddressChange(event) {
        this.searchAddress = event.target.value;
    }

    async handleSearch() {
        if (!this.searchAddress) {
            return;
        }

        try {
            // Geocode the address to get lat/lng
            const location = await this.geocodeAddress(this.searchAddress);
            if (!location) {
                // Handle error
                return;
            }

            this.center = { latitude: location.lat, longitude: location.lng };
            this.zoomLevel = 10;

            // Query opportunities within radius
            this.opportunities = await getOpportunitiesWithinRadius({
                lat: location.lat,
                lng: location.lng,
                radiusKm: this.radius
            });

            // Create map markers
            this.mapMarkers = this.opportunities.map(opp => ({
                location: {
                    Latitude: opp.BillingLatitude,
                    Longitude: opp.BillingLongitude
                },
                title: opp.Name,
                description: `${opp.BillingStreet}, ${opp.BillingCity}`,
                value: opp.Id
            }));

            this.selectedOpportunity = null; // Reset selection

        } catch (error) {
            console.error('Error during search:', error);
        }
    }

    async geocodeAddress(address) {
        // Placeholder geocoding - in production, use Google Maps API or similar
        // For demo, hardcode for "Chennai"
        if (address.toLowerCase().includes('chennai')) {
            return { lat: 13.0827, lng: 80.2707 };
        }
        // For other addresses, return null or implement full geocoding
        // Example: fetch from Google Maps API
        // const apiKey = 'YOUR_API_KEY'; // Store in custom setting or label
        // const response = await fetch(`https://maps.googleapis.com/maps/api/geocode/json?address=${encodeURIComponent(address)}&key=${apiKey}`);
        // const data = await response.json();
        // if (data.results && data.results.length > 0) {
        //     const loc = data.results[0].geometry.location;
        //     return { lat: loc.lat, lng: loc.lng };
        // }
        return null;
    }

    handleMarkerClick(event) {
        const markerValue = event.detail.selectedMarkerValue;
        this.selectedOpportunity = this.opportunities.find(opp => opp.Id === markerValue);
    }
        // Let's modify to store opportunities
        this.selectedOpportunity = this.mapMarkers.find(marker => marker.value === markerValue);
        // But selectedOpportunity needs the full object
        // So, better to keep the opportunities list
    }
}