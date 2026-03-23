import { LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import getOpportunitiesByAddress from '@salesforce/apex/OpportunityMapController.getOpportunitiesByAddress';

export default class OpportunityMap extends LightningElement {
    @track searchAddress = '';
    @track mapMarkers = [];
    @track center = { latitude: 0, longitude: 0 };
    @track zoomLevel = 10;
    @track selectedOpportunity = null;
    @track opportunities = [];
    @track isLoading = false;
    radius = 7; // km

    handleAddressChange(event) {
        this.searchAddress = event.target.value;
    }

    async handleSearch() {
        if (!this.searchAddress) {
            return;
        }

        this.isLoading = true;
        try {
            // Query opportunities based on the entered address and radius
            this.opportunities = await getOpportunitiesByAddress({
                searchTerm: this.searchAddress,
                radiusKm: this.radius
            });

            if (this.opportunities && this.opportunities.length) {
                const firstOpp = this.opportunities[0];
                this.center = {
                    latitude: firstOpp.Account.BillingLatitude,
                    longitude: firstOpp.Account.BillingLongitude
                };
                this.zoomLevel = 10;
            }

            // Create map markers
            this.mapMarkers = this.opportunities.map(opp => ({
                location: {
                    Latitude: opp.Account.BillingLatitude,
                    Longitude: opp.Account.BillingLongitude
                },
                title: opp.Name,
                description: `${opp.Account.BillingStreet}, ${opp.Account.BillingCity}`,
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

    handleMarkerClick(event) {
        const markerValue = event.detail.selectedMarkerValue;
        this.selectedOpportunity = this.opportunities.find(opp => opp.Id === markerValue);
    }
}