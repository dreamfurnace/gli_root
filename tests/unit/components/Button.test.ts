import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import Button from '../../../gli_user-frontend/src/components/ui/Button/Button.vue'

describe('Button', () => {
  it('기본 렌더링', () => {
    const wrapper = mount(Button, { slots: { default: '테스트 버튼' } })
    expect(wrapper.text()).toContain('테스트 버튼')
    expect(wrapper.classes()).toContain('ui-button')
  })

  it('variant prop에 따라 클래스가 적용된다', () => {
    const wrapper = mount(Button, {
      props: { variant: 'secondary' },
      slots: { default: 'Secondary' },
    })
    expect(wrapper.classes()).toContain('ui-button--secondary')
  })
})
