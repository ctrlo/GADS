import { Component } from 'component'
import { sidebarObservable } from './sidebarObservable'

const COLLAPSED_CLASS = 'sidebar--collapsed'
const EXPANDED_CLASS = 'main--expanded'
const KEY_NAV_STATE = 'main-menu::state'
const NAV_STATE_EXPANDED = 'expanded'
const NAV_STATE_COLLAPSED = 'collapsed'

/**
 * Sidebar Component
 */
class SidebarComponent extends Component {
    /**
     * Create a Sidebar
     * @param {HTMLElement} element The element to attach the component to
     */
    constructor(element) {
        super(element)
        this.el = $(this.element)
        this.isMobile = this.isMobileResolution
        this.toggle = this.el.find('.sidebar__toggle')
        this.currentState = localStorage.getItem(KEY_NAV_STATE) || (this.isMobile ? NAV_STATE_COLLAPSED : NAV_STATE_EXPANDED)

        this.initSidebar()
    }

    /**
     * Initialize the sidebar
     */
    initSidebar() {
        const sidebarToggle = this.el.find('.sidebar__toggle')
        sidebarObservable.addSubscriber(this)

        if (!sidebarToggle) {
            return
        }

        if (this.isMobile) {
            this.collapseSidebar()
        } else {
            this.currentState === NAV_STATE_COLLAPSED ? this.collapseSidebar() : this.expandSidebar()
        }

        $(window).on("resize", () => { this.handleResize() })

        sidebarToggle.on("click", () => { this.handleClick() })
    }

    /**
     * Handle the resize
     */
    handleResize() {
        if (this.isMobileResolution) {
            if (!this.isMobile) {
                this.collapseSidebar()
                this.isMobile = true
            }
        } else {
            if (this.isMobile) {
                this.expandSidebar()
                this.isMobile = false
            }
        }
    }

    /**
     * Handle the click event
     */
    handleClick() {
        if (this.el.hasClass(COLLAPSED_CLASS)) {
            this.expandSidebar()
        } else {
            this.collapseSidebar()
        }
        sidebarObservable.sideBarChange()
    }

    /**
     * Collapse the sidebar
     */
    collapseSidebar() {
        $("main").addClass(EXPANDED_CLASS)
        this.el.addClass(COLLAPSED_CLASS)
        $(this.toggle).attr('aria-expanded', 'false')
        $(document).find("main").addClass(EXPANDED_CLASS)

        if (!this.isMobile) {
            this.currentState = NAV_STATE_COLLAPSED
            localStorage.setItem(KEY_NAV_STATE, this.currentState)
        }
    }

    /**
     * Expand the sidebar
     */
    expandSidebar() {
        $("main").removeClass(EXPANDED_CLASS)
        this.el.removeClass(COLLAPSED_CLASS)
        $(this.toggle).attr('aria-expanded', 'true')
        $(document).find("main").removeClass(EXPANDED_CLASS)

        if (!this.isMobile) {
            this.currentState = NAV_STATE_EXPANDED
            localStorage.setItem(KEY_NAV_STATE, this.currentState)
        }
    }

    /**
     * Is the resolution mobile
     * @returns {boolean} True if the resolution is mobile
     */
    get isMobileResolution() {
        return window.matchMedia("(max-width: 991px)").matches
    }
}

export default SidebarComponent
