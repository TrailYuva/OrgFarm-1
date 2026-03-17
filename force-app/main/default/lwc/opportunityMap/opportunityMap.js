import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOpportunitiesWithinRadius from '@salesforce/apex/OpportunityMapController.getOpportunitiesWithinRadius';
import getGoogleMapsApiKey from '@salesforce/apex/OpportunityMapController.getGoogleMapsApiKey';

export default class OpportunityMap extends LightningElement {
    @track searchAddress = '';
    @track mapMarkers = [];
    @track center = { latitude: 0, longitude: 0 };
    @track zoomLevel = 10;
    @track selectedOpportunity = null;
    @track opportunities = [];
    @track isLoading = false;
    googleMapsApiKey = '';
    radius = 7; // km

    connectedCallback() {
        this.loadGoogleMapsApiKey();
    }

    async loadGoogleMapsApiKey() {
        try {
            this.googleMapsApiKey = await getGoogleMapsApiKey();
        } catch (error) {
            console.error('Error loading API key:', error);
        }
    }

    handleAddressChange(event) {
        this.searchAddress = event.target.value;
    }

    async handleSearch() {
        if (!this.searchAddress) {
            return;
        }

        this.isLoading = true;
        try {
            // Geocode the address to get lat/lng
            const location = await this.geocodeAddress(this.searchAddress);
            if (!location) {
                this.dispatchEvent(new ShowToastEvent({
                    title: 'Geocoding Error',
                    message: 'Unable to find the location for the entered address.',
                    variant: 'error'
                }));
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
            this.dispatchEvent(new ShowToastEvent({
                title: 'Search Error',
                message: 'An error occurred while searching for opportunities.',
                variant: 'error'
            }));
        } finally {
            this.isLoading = false;
        }
    }

    async geocodeAddress(address) {
        try {
            const response = await fetch(`https://maps.googleapis.com/maps/api/geocode/json?address=${encodeURIComponent(address)}&key=${this.googleMapsApiKey}`);
            const data = await response.json();
            if (data.results && data.results.length > 0) {
                const loc = data.results[0].geometry.location;
                return { lat: loc.lat, lng: loc.lng };
            }
        } catch (error) {
            console.error('Geocoding error:', error);
        }
        return null;
    }

    handleMarkerClick(event) {
        const markerValue = event.detail.selectedMarkerValue;
        this.selectedOpportunity = this.opportunities.find(opp => opp.Id === markerValue);
    }
}