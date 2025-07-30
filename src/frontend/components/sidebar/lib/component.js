import { Component } from 'component';
import { sidebarObservable } from './sidebarObservable';

const COLLAPSED_CLASS = 'sidebar--collapsed';
const EXPANDED_CLASS = 'main--expanded';
const KEY_NAV_STATE = 'main-menu::state';
const NAV_STATE_EXPANDED = 'expanded';
const NAV_STATE_COLLAPSED = 'collapsed';

/**
 * SidebarComponent class to manage the sidebar behavior.
 */
class SidebarComponent extends Component {
    /**
     * Creates an instance of SidebarComponent.
     * @param {HTMLElement} element The HTML element representing the sidebar.
     */
    constructor(element) {
        super(element);
        this.el = $(this.element);
        this.isMobile = this.isMobileResolution();
        this.toggle = this.el.find('.sidebar__toggle');
        this.currentState = localStorage.getItem(KEY_NAV_STATE) || (this.isMobile ? NAV_STATE_COLLAPSED : NAV_STATE_EXPANDED);

        this.initSidebar();
        this.el.removeClass('hidden');
    }

    /**
     * Initializes the sidebar by setting up the toggle button and handling the initial state.
     */
    initSidebar() {
        const sidebarToggle = this.el.find('.sidebar__toggle');
        sidebarObservable.addSubscriber(this);

        if (!sidebarToggle) {
            return;
        }

        if (this.isMobile) {
            this.collapseSidebar();
        } else if (this.currentState === NAV_STATE_COLLAPSED) {
            this.collapseSidebar();
        } else {
            this.expandSidebar();
        }

        $(window).on('resize', () => { this.handleResize(); });

        sidebarToggle.on('click', () => { this.handleClick(); });
    }

    /**
     * Handles the window resize event to adjust the sidebar state based on resolution.
     */
    handleResize() {
        if (this.isMobileResolution()) {
            if (!this.isMobile) {
                this.collapseSidebar();
                this.isMobile = true;
            }
        } else {
            if (this.isMobile) {
                this.expandSidebar();
                this.isMobile = false;
            }
        }
    }

    /**
     * Handles the click event on the sidebar toggle button.
     */
    handleClick() {
        if (this.el.hasClass(COLLAPSED_CLASS)) {
            this.expandSidebar();
        } else {
            this.collapseSidebar();
        }
        sidebarObservable.sideBarChange();
    }

    /**
     * Collapses the sidebar by adding the collapsed class and updating the main content area.
     */
    collapseSidebar() {
        this.el.addClass(COLLAPSED_CLASS);
        $(this.toggle).attr('aria-expanded', 'false');
        $(document).find('main')
            .addClass(EXPANDED_CLASS);

        if (!this.isMobile) {
            this.currentState = NAV_STATE_COLLAPSED;
            localStorage.setItem(KEY_NAV_STATE, this.currentState);
        }
    }

    /**
     * Expands the sidebar by removing the collapsed class and updating the main content area.
     */
    expandSidebar() {
        this.el.removeClass(COLLAPSED_CLASS);
        $(this.toggle).attr('aria-expanded', 'true');
        $(document).find('main')
            .removeClass(EXPANDED_CLASS);

        if (!this.isMobile) {
            this.currentState = NAV_STATE_EXPANDED;
            localStorage.setItem(KEY_NAV_STATE, this.currentState);
        }
    }

    /**
     * Checks if the current resolution is mobile.
     * @returns {boolean} True if the resolution is mobile, false otherwise.
     */
    isMobileResolution() {
        return window.matchMedia('(max-width: 991px)').matches;
    }
}

export default SidebarComponent;
