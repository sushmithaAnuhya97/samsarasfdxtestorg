import { LightningElement } from 'lwc';
import SAMSARA_LOGO from '@salesforce/resourceUrl/Samsara_Logo';
import FACEBOOK_ICON from '@salesforce/resourceUrl/FacebookLogo';
import X_ICON from '@salesforce/resourceUrl/Xlogo';
import INSTAGRAM_ICON from '@salesforce/resourceUrl/InstagramLogo';
import LINKEDIN_ICON from '@salesforce/resourceUrl/LinkedinLogo';
import YOUTUBE_ICON from '@salesforce/resourceUrl/YoutubeLogo';

export default class SamsaraFooter extends LightningElement {
    samsaraLogo = SAMSARA_LOGO;
    facebookIcon = FACEBOOK_ICON;
    xIcon = X_ICON;
    instagramIcon = INSTAGRAM_ICON;
    linkedinIcon = LINKEDIN_ICON;
    youtubeIcon = YOUTUBE_ICON;

    selectedCountry = 'US';
    isDropdownVisible = false;

    get languageOptions() {
        return [
            { label: 'Canada', value: 'CA', iconName: 'utility:world'},
            { label: 'DACH', value: 'DE', iconName: 'utility:world'},            
            { label: 'United States', value: 'US', iconName: 'utility:world'},
            { label: 'France', value: 'FR', iconName: 'utility:world'},
            { label: 'Canada - Français', value: 'FR-CA', iconName: 'utility:world' },
            { label: 'México', value: 'MX', iconName: 'utility:world' },
            { label: 'Nederland', value: 'NL', iconName: 'utility:world' },
            { label: 'United Kingdom', value: 'UK', iconName: 'utility:world' }
        ];
    }

    get selectedCountryLabel() {
        const selectedOption = this.languageOptions.find(option => option.value === this.selectedCountry);
        return selectedOption ? selectedOption.label : 'Select Country';
    }

    get isUsSelected() {
        return this.selectedCountry === 'US';
    }

    get isCaSelected() {
        return this.selectedCountry === 'CA';
    }

    get isDeSelected() {
        return this.selectedCountry === 'DE';
    }

    get isFrSelected() {
        return this.selectedCountry === 'FR';
    }

    get isFrCaSelected() {
        return this.selectedCountry === 'FR-CA';
    }

    get isMxSelected() {
        return this.selectedCountry === 'MX';
    }

    get isNlSelected() {
        return this.selectedCountry === 'NL';
    }

    get isUkSelected() {
        return this.selectedCountry === 'UK';
    }

    handleCountryChange(event) {
        const selectedValue = event.target.dataset.value;
        this.selectedCountry = selectedValue; 
        this.isDropdownVisible = false; 
    }

    handleCountryClick() {
        this.isDropdownVisible = !this.isDropdownVisible;
    }
}